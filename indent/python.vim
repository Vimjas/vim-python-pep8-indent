" PEP8 compatible Python indent file
" Language:         Python
" Maintainer:       Hynek Schlawack <hs@ox.cx>
" Prev Maintainer:  Eric Mc Sween <em@tomcom.de> (address invalid)
" Original Author:  David Bustos <bustos@caltech.edu> (address invalid)
" Contributor:      Johann Klähn <kljohann@gmail.com>
" License:          Public Domain

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
    finish
endif
let b:did_indent = 1

setlocal expandtab
setlocal nolisp
setlocal autoindent
setlocal indentexpr=GetPythonIndent(v:lnum)
setlocal indentkeys=!^F,o,O,<:>,0),0],0},=elif,=except

let s:maxoff = 50
let s:block_rules = {
  \ '^\s*\(elif\|else\)\>': ['if', 'elif'],
  \ '^\s*\(except\|finally\)\>': ['try', 'except']
  \ }
let s:paren_pairs = ['()', '{}', '[]']

" compatibility with vim patch 7.3.629: 'sw' can be set to -1 to follow 'ts'
if exists('*shiftwidth')
    function! s:sw()
        return shiftwidth()
    endfunction
else
    function! s:sw()
        return &sw
    endfunction
endif

function! s:pair_sort(x, y)
    if a:x[0] == a:y[0]
        return a:x[1] == a:y[1] ? 0 : a:x[1] > a:y[1] ? 1 : -1
    else
        return a:x[0] > a:y[0] ? 1 : -1
    endif
endfunction

" Find backwards the closest open parenthesis/bracket/brace.
function! s:find_opening_paren(...)
    " optional arguments: line and column (defaults to 1) to search around
    if a:0 > 0
        let view = winsaveview()
        call cursor(a:1, a:0 > 1 ? a:2 : 1)
        let ret = s:find_opening_paren()
        call winrestview(view)
        return ret
    endif

    let stopline = max([0, line('.') - s:maxoff])

    " Skip strings and comments
    let skip = 'synIDattr(synID(line("."), col("."), 0), "name") ' .
             \ '=~? "string\\|comment"'

    " Return if cursor is in a comment or string
    exe 'if' skip '| return [0, 0] | endif'

    let positions = []
    for p in s:paren_pairs
        call add(positions, searchpairpos('\V'.p[0], '', '\V'.p[1], 'bnW', skip, stopline))
    endfor

    " Remove empty matches and return the type with the closest match
    call filter(positions, 'v:val[0]')
    call sort(positions, 's:pair_sort')

    return get(positions, 0, [0, 0])
endfunction

" Find the start of a multi-line statement
function! s:find_start_of_multiline_statement(lnum)
    let lnum = a:lnum
    while lnum > 0
        if getline(lnum - 1) =~ '\\$'
            let lnum = prevnonblank(lnum - 1)
        else
            let [paren_lnum, _] = s:find_opening_paren(lnum)
            if paren_lnum < 1
                return lnum
            else
                let lnum = paren_lnum
            endif
        endif
    endwhile
endfunction

" Find the block starter that matches the current line
function! s:find_start_of_block(lnum, types)
    let re = '\V\^\s\*\('.join(a:types, '\|').'\)\>'

    let lnum = a:lnum
    let last_indent = indent(lnum) + 1
    while lnum > 0 && last_indent > 0
        if indent(lnum) < last_indent
            if getline(lnum) =~ re
                return lnum
            endif
            let last_indent = indent(lnum)
        endif
        let lnum = prevnonblank(lnum - 1)
    endwhile
    return 0
endfunction

" Line up with open parenthesis/bracket/brace.
function! s:indent_like_opening_paren(lnum)
    let [paren_lnum, paren_col] = s:find_opening_paren(a:lnum)
    if paren_lnum <= 0
        return -2
    endif

    " TODO: start argument of match is byte-based index, may cause problems
    " with multibyte strings.
    " TODO: does match() use 'magic' ?

    let nothing_after_opening_paren =
      \ match(getline(paren_lnum), '[([{]\s*$', paren_col - 1) != -1
    let closing_paren =
      \ match(getline(a:lnum), '^\s*[])}]') != -1

    if nothing_after_opening_paren
        if closing_paren
            return indent(paren_lnum)
        else
            return indent(paren_lnum) + s:sw()
        endif
    else
        return paren_col
    endif
endfunction

" Match indent of first block of this type.
function! s:indent_like_block(lnum)
    let text = getline(a:lnum)

    for [line_re, blocks] in items(s:block_rules)
        if text !~# line_re
            continue
        endif

        let lnum = s:find_start_of_block(a:lnum - 1, blocks)
        if lnum > 0
            return indent(lnum)
        else
            return -1
        endif
    endfor

    return -2
endfunction

function! s:indent_like_previous_line(lnum)
    let lnum = prevnonblank(a:lnum - 1)
    let text = getline(lnum)
    let start = s:find_start_of_multiline_statement(lnum)

    " If this line is explicitly joined, find an indentation that looks good.
    if text =~ '\\$'
        let compound_statement = '^\s*\(if\|while\|with\|for\s.*\sin\|except\)\s*'
        let maybe_indent = matchend(getline(start), compound_statement)
        if maybe_indent != -1
            return maybe_indent
        else
            return indent(start) + s:sw() * 2
        endif
    endif

    " If the previous line ended with a colon and is not a comment, indent
    " relative to statement start.
    if text =~ '^[^#]*:\s*\(#.*\)\?$'
        return indent(start) + s:sw()
    endif

    " If the previous statement was a stop-execution statement or a pass
    if getline(start) =~# '^\s*\(break\|continue\|raise\|return\|pass\)\>'
        " Remove one level of indentation if the user hasn't already dedented
        if indent(a:lnum) > indent(start) - s:sw()
            return indent(start) - s:sw()
        endif
        " Otherwise, trust the user
        return -1
    endif

    " In all other cases, line up with the start of the previous statement.
    return indent(start)
endfunction

function! GetPythonIndent(lnum)

    " First line has indent 0
    if a:lnum == 1
        return 0
    endif

    " Parens: If we can find an open parenthesis/bracket/brace, line up with it.
    let indent = s:indent_like_opening_paren(a:lnum)
    if indent >= -1
        return indent
    endif

    " Blocks: Match indent of first block of this type.
    let indent = s:indent_like_block(a:lnum)
    if indent >= -1
        return indent
    endif

    return s:indent_like_previous_line(a:lnum)
endfunction
