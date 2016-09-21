" PEP8 compatible Python indent file
" Language:         Python
" Maintainer:       Hynek Schlawack <hs@ox.cx>
" Prev Maintainer:  Eric Mc Sween <em@tomcom.de> (address invalid)
" Original Author:  David Bustos <bustos@caltech.edu> (address invalid)
" License:          CC0
"
" vim-python-pep8-indent - A nicer Python indentation style for vim.
" Written in 2004 by David Bustos <bustos@caltech.edu>
" Maintained from 2004-2005 by Eric Mc Sween <em@tomcom.de>
" Maintained from 2013 by Hynek Schlawack <hs@ox.cx>
"
" To the extent possible under law, the author(s) have dedicated all copyright
" and related and neighboring rights to this software to the public domain
" worldwide. This software is distributed without any warranty.
" You should have received a copy of the CC0 Public Domain Dedication along
" with this software. If not, see
" <http://creativecommons.org/publicdomain/zero/1.0/>.

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
    finish
endif
let b:did_indent = 1

setlocal expandtab
setlocal nolisp
setlocal autoindent
setlocal indentexpr=GetPythonPEPIndent(v:lnum)
setlocal formatexpr=GetPythonPEPFormat(v:lnum,v:count)
setlocal indentkeys=!^F,o,O,<:>,0),0],0},=elif,=except
setlocal tabstop=4
setlocal softtabstop=4
setlocal shiftwidth=4

if !exists('g:python_pep8_indent_multiline_string')
    let g:python_pep8_indent_multiline_string = 0
endif

let s:maxoff = 50
let s:block_rules = {
            \ '^\s*elif\>': ['if', 'elif'],
            \ '^\s*except\>': ['try', 'except'],
            \ '^\s*finally\>': ['try', 'except', 'else']
            \ }
let s:block_rules_multiple = {
            \ '^\s*else\>': ['if', 'elif', 'for', 'try', 'except'],
            \ }
let s:paren_pairs = ['()', '{}', '[]']
if &ft == 'pyrex' || &ft == 'cython'
    let b:control_statement = '\v^\s*(class|def|if|while|with|for|except|cdef|cpdef)>'
else
    let b:control_statement = '\v^\s*(class|def|if|while|with|for|except)>'
endif
let s:stop_statement = '^\s*\(break\|continue\|raise\|return\|pass\)\>'

" Skip strings and comments. Return 1 for chars to skip.
" jedi* refers to syntax definitions from jedi-vim for call signatures, which
" are inserted temporarily into the buffer.
let s:skip_special_chars = 'synIDattr(synID(line("."), col("."), 0), "name") ' .
            \ '=~? "\\vstring|comment|jedi\\S"'

let s:skip_string = 'synIDattr(synID(line("."), col("."), 0), "name") ' .
            \ '=~? "\\vstring|bytes\\S"'
let s:skip_after_opening_paren = 'synIDattr(synID(line("."), col("."), 0), "name") ' .
            \ '=~? "\\vcomment|jedi\\S"'

" Also ignore anything concealed.
" Wrapper around synconcealed for older Vim (7.3.429, used on Travis CI).
function! s:is_concealed(line, col)
    let concealed = synconcealed(a:line, a:col)
    return len(concealed) && concealed[0]
endfunction
if has('conceal')
    let s:skip_special_chars .= '|| s:is_concealed(line("."), col("."))'
endif


let s:skip_search = 'synIDattr(synID(line("."), col("."), 0), "name") ' .
            \ '=~? "comment"'

" Use 'shiftwidth()' instead of '&sw'.
" (Since Vim patch 7.3.629, 'shiftwidth' can be set to 0 to follow 'tabstop').
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

    " Return if cursor is in a comment.
    exe 'if' s:skip_search '| return [0, 0] | endif'

    let positions = []
    for p in s:paren_pairs
        call add(positions, searchpairpos(
           \ '\V'.p[0], '', '\V'.p[1], 'bnW', s:skip_special_chars, stopline))
    endfor

    " Remove empty matches and return the type with the closest match
    call filter(positions, 'v:val[0]')
    call sort(positions, 's:pair_sort')

    return get(positions, -1, [0, 0])
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

" Find possible indent(s) of the block starter that matches the current line.
function! s:find_start_of_block(lnum, types, multiple)
    let r = []
    let types = copy(a:types)
    let re = '\V\^\s\*\('.join(a:types, '\|').'\)\>'
    let lnum = a:lnum
    let last_indent = indent(lnum) + 1
    while lnum > 0 && last_indent > 0
        let indent = indent(lnum)
        if indent < last_indent
            for type in types
                let re = '\v^\s*'.type.'>'
                if getline(lnum) =~# re
                    if !a:multiple
                        return [indent]
                    endif
                    if index(r, indent) == -1
                        let r += [indent]
                    endif
                    " Remove any handled type, e.g. 'if'.
                    call remove(types, index(types, type))
                endif
            endfor
            let last_indent = indent(lnum)
        endif
        let lnum = prevnonblank(lnum - 1)
    endwhile
    return r
endfunction

" Is "expr" true for every position in "lnum", beginning at "start"?
" (optionally up to a:1 / 4th argument)
function! s:match_expr_on_line(expr, lnum, start, ...)
    let text = getline(a:lnum)
    let end = a:0 ? a:1 : len(text)
    if a:start > end
        return 1
    endif
    let save_pos = getpos('.')
    let r = 1
    for i in range(a:start, end)
        call cursor(a:lnum, i)
        if !(eval(a:expr) || text[i-1] =~ '\s')
            let r = 0
            break
        endif
    endfor
    call setpos('.', save_pos)
    return r
endfunction

" Line up with open parenthesis/bracket/brace.
function! s:indent_like_opening_paren(lnum)
    let [paren_lnum, paren_col] = s:find_opening_paren(a:lnum)
    if paren_lnum <= 0
        return -2
    endif
    let text = getline(paren_lnum)
    let base = indent(paren_lnum)

    let nothing_after_opening_paren = s:match_expr_on_line(
                \ s:skip_after_opening_paren, paren_lnum, paren_col+1)
    let starts_with_closing_paren = getline(a:lnum) =~ '^\s*[])}]'

    if nothing_after_opening_paren
        if starts_with_closing_paren
            let res = base
        else
            let res = base + s:sw()
        endif
    else
        " Indent to match position of opening paren.
        let res = paren_col
    endif

    " If this line is the continuation of a control statement
    " indent further to distinguish the continuation line
    " from the next logical line.
    if text =~# b:control_statement && res == base + s:sw()
        return base + s:sw() * 2
    else
        return res
    endif
endfunction

" Match indent of first block of this type.
function! s:indent_like_block(lnum)
    let text = getline(a:lnum)
    for [multiple, block_rules] in [
                \ [0, s:block_rules],
                \ [1, s:block_rules_multiple]]
        for [line_re, blocks] in items(block_rules)
            if text !~# line_re
                continue
            endif

            let indents = s:find_start_of_block(a:lnum - 1, blocks, multiple)
            if !len(indents)
                return -1
            endif
            if len(indents) == 1
                return indents[0]
            endif

            " Multiple valid indents, e.g. for 'else' with both try and if.
            let indent = indent(a:lnum)
            if index(indents, indent) != -1
                " The indent is valid, keep it.
                return indent
            endif
            " Fallback to the first/nearest one.
            return indents[0]
        endfor
    endfor
    return -2
endfunction

function! s:indent_like_previous_line(lnum)
    let lnum = prevnonblank(a:lnum - 1)

    " No previous line, keep current indent.
    if lnum < 1
      return -1
    endif

    let text = getline(lnum)
    let start = s:find_start_of_multiline_statement(lnum)
    let base = indent(start)
    let current = indent(a:lnum)

    " Jump to last character in previous line.
    call cursor(lnum, len(text))
    let ignore_last_char = eval(s:skip_special_chars)

    " Search for final colon that is not inside something to be ignored.
    while 1
        let curpos = getpos(".")[2]
        if curpos == 1 | break | endif
        if eval(s:skip_special_chars) || text[curpos-1] =~ '\s'
            normal! h
            continue
        elseif text[curpos-1] == ':'
            return base + s:sw()
        endif
        break
    endwhile

    if text =~ '\\$' && !ignore_last_char
        " If this line is the continuation of a control statement
        " indent further to distinguish the continuation line
        " from the next logical line.
        if getline(start) =~# b:control_statement
            return base + s:sw() * 2
        endif

        " Nest (other) explicit continuations only one level deeper.
        return base + s:sw()
    endif

    " If the previous statement was a stop-execution statement or a pass
    if getline(start) =~# s:stop_statement
        " Remove one level of indentation if the user hasn't already dedented
        if indent(a:lnum) > base - s:sw()
            return base - s:sw()
        endif
        " Otherwise, trust the user
        return -1
    endif

    if s:is_dedented_already(current, base)
        return -1
    endif

    " In all other cases, line up with the start of the previous statement.
    return base
endfunction

" If this line is dedented and the number of indent spaces is valid
" (multiple of the indentation size), trust the user.
function! s:is_dedented_already(current, base)
    let dedent_size = a:current - a:base
    return (dedent_size < 0 && a:current % s:sw() == 0) ? 1 : 0
endfunction

" Is the syntax at lnum (and optionally cnum) a python string?
function! s:is_python_string(lnum, ...)
    let line = getline(a:lnum)
    let linelen = len(line)
    if linelen < 1
      let linelen = 1
    endif
    let cols = a:0 ? type(a:1) != type([]) ? [a:1] : a:1 : range(1, linelen)
    for cnum in cols
        if match(map(synstack(a:lnum, cnum),
                    \ 'synIDattr(v:val,"name")'), 'python\S*String') == -1
            return 0
        end
    endfor
    return 1
endfunction

function! GetPythonPEPIndent(lnum)
    " First line has indent 0
    if a:lnum == 1
        return 0
    endif

    let line = getline(a:lnum)
    let prevline = getline(a:lnum-1)

    " Multilinestrings: continous, docstring or starting.
    if s:is_python_string(a:lnum-1, len(prevline))
                \ && (s:is_python_string(a:lnum, 1)
                \     || match(line, '^\%("""\|''''''\)') != -1)

        " Indent closing quotes as the line with the opening ones.
        let match_quotes = match(line, '^\s*\zs\%("""\|''''''\)')
        if match_quotes != -1
            " closing multiline string
            let quotes = line[match_quotes:match_quotes+2]
            let pairpos = searchpairpos(quotes, '', quotes, 'b')
            if pairpos[0] != 0
                return indent(pairpos[0])
            else
                " TODO: test to cover this!
            endif
        endif

        if s:is_python_string(a:lnum-1)
            " Previous line is (completely) a string.
            return indent(a:lnum-1)
        endif

        if match(prevline, '^\s*\%("""\|''''''\)') != -1
            " docstring.
            return indent(a:lnum-1)
        endif

        let indent_multi = get(b:, 'python_pep8_indent_multiline_string',
                    \ get(g:, 'python_pep8_indent_multiline_string', 0))
        if match(prevline, '\v%("""|'''''')$') != -1
            " Opening multiline string, started in previous line.
            if (&autoindent && indent(a:lnum) == indent(a:lnum-1))
                        \ || match(line, '\v^\s+$') != -1
                " <CR> with empty line or to split up 'foo("""bar' into
                " 'foo("""' and 'bar'.
                if indent_multi == -2
                    return indent(a:lnum-1) + s:sw()
                endif
                return indent_multi
            endif
        endif

        " Keep existing indent.
        if match(line, '\v^\s*\S') != -1
            return -1
        endif

        if indent_multi != -2
            return indent_multi
        endif

        return s:indent_like_opening_paren(a:lnum)
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

function s:SearchPosWithSkip(pattern, flags, skip, stopline)
    "
    " Returns true if a match is found for {pattern}, but ignores matches
    " where {skip} evaluates to false. This allows you to do nifty things
    " like, say, only matching outside comments, only on odd-numbered lines,
    " or whatever else you like.
    "
    " Mimics the built-in search() function, but adds a {skip} expression
    " like that available in searchpair() and searchpairpos().
    " (See the Vim help on search() for details of the other parameters.)
    "
    " Note the current position, so that if there are no unskipped
    " matches, the cursor can be restored to this location.
    "
    let l:flags = a:flags
    let l:movepos = getpos('.')
    let l:firstmatch = []
    let l:pos = [0, 0, 0, 0]

    " Loop as long as {pattern} continues to be found.
    "
    while search(a:pattern, l:flags, a:stopline) > 0
        if l:firstmatch == []
            let l:firstmatch = getpos('.')
            let l:flags = substitute(l:flags, 'c', '', '')
        elseif l:firstmatch == getpos('.')
            break
        endif

        " If {skip} is true, ignore this match and continue searching.
        "
        if eval(a:skip)
            continue
        endif

        " If we get here, {pattern} was found and {skip} is false,
        " so this is a match we don't want to ignore. Update the
        " match position and stop searching.
        "
        let l:pos = getpos('.')
        let l:movepos = getpos('.')
        break

    endwhile

    " Jump to the position of the unskipped match, or to the original
    " position if there wasn't one.
    "

    call setpos('.', l:movepos)
    return [l:pos[1], l:pos[2]]

endfunction

function s:IsInComment(lnum, col)
    return synIDattr(synID(a:lnum, a:col, 0), 'name') =~? 'comment'
endfunction

function s:IsInMultilineString(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 0), 'name') =~? 'multiline'
endfunction


function! GetPythonPEPFormat(lnum, count)
  let l:tw = &textwidth ? &textwidth : 79

  let l:winview = winsaveview()

  let l:count = a:count
  let l:first_char = indent(a:lnum) + 1

  if mode() ==? 'i' " gq was not pressed, but tw was set
    return 1
  endif

  if virtcol('$') <= l:tw + 1 && l:count == 1 " No need for gq
    return 1
  endif

  " Put all the lines on one line and do normal splitting after that.
  if l:count > 1
    while l:count > 1
      let l:count -= 1
      normal! J
    endwhile
  endif

  let l:twplus1 = s:VirtcolToCol(a:lnum, l:tw + 1)
  let l:twminus1 = s:VirtcolToCol(a:lnum, l:tw - 1)

  call cursor(a:lnum, l:twplus1)
  let l:orig_breakpoint = searchpos(' ', 'bcW', a:lnum)
  let l:orig_breakpointview = winsaveview()
  " If breaking inside string extra space is needed for the space and quote
  call cursor(a:lnum, l:twminus1)
  let l:better_orig_breakpoint = searchpos(' ', 'bcW', a:lnum)
  let l:better_orig_breakpointview = winsaveview()
  call cursor(a:lnum, l:twplus1)
  let l:breakpoint = s:SearchPosWithSkip(' ', 'bcW', s:skip_string, a:lnum)
  let l:breakpointview = winsaveview()

  " No need for special treatment, normal gq handles docstrings fine
  if s:IsInMultilineString(l:orig_breakpoint[0], l:orig_breakpoint[1])
              \|| s:IsInComment(l:orig_breakpoint[0], l:orig_breakpoint[1])
    call winrestview(l:winview)
    return 1
  endif

  " If the match is at the indent level try breaking after string as last
  " resort
  " if l:breakpoint[1] <= indent(a:lnum)
  "   call cursor(a:lnum, l:tw + 1)
  "   "Search for a space that is not trailing whitespace
  "   let l:breakpoint = s:SearchPosWithSkip(' [^ ]', 'cW', s:skip_string, a:lnum)
  " endif


  "" Fallback to old behaviour when nothing is found
  " if l:breakpoint[1] == 0
  "   call winrestview(l:winview)
  "   return 1
  " endif
  " let l:breakpoint_brackets = s:isBetweenBrackets(l:breakpointview)
  " let l:orig_breakpoint_brackets = s:isBetweenBrackets(l:orig_breakpointview)

  "echom s:isBetweenPair('(', ')', l:breakpointview, s:skip_string)
  "echom s:isBetweenPair('{', '}', l:breakpointview, s:skip_string)
  "echom s:isBetweenPair('\[', '\]', l:breakpointview, s:skip_string)
  "echom s:isBetweenPair('(', ')', l:orig_breakpointview, s:skip_string)
  "echom s:isBetweenPair('{', '}', l:orig_breakpointview, s:skip_string)
  "echom s:isBetweenPair('\[', '\]', l:orig_breakpointview, s:skip_string)
  "echom 'new'
  "echom l:breakpoint[1]
  "echom 'orig'
  "echom l:orig_breakpoint[1]

  "Order of breaking:
  " 1. Only break on breakpoints that have actually been found
  " 2. Breaking inside brackets is preferred (no backslash needed)
  " 3. Breking outside a string is preferred (new breakpoint)
  " 4. Possible future: breaking at space is preferred
  if l:breakpoint[1] > indent(a:lnum) && s:isBetweenBrackets(l:breakpointview)
    "echom 'between brackets'
    call winrestview(l:breakpointview)
    call feedkeys("r\<CR>", 'n')
  else
    "echom 'zooooi'
    if l:better_orig_breakpoint[1] > indent(a:lnum)
                \ && s:isBetweenBrackets(l:better_orig_breakpointview)
        " echom 'doing the quotes'
        call winrestview(l:better_orig_breakpointview)
        let l:pos_start_string =
                    \ s:SearchPosWithSkip('.', 'bcW', s:skip_string, a:lnum)
        call winrestview(l:better_orig_breakpointview)
        " Find the type of start quote of the string
        " and skip charactars at the start of the string like b/u/r
        let l:extra_chars = 0
        let l:cur_char = getline(a:lnum)[l:pos_start_string[1]]
        while l:cur_char !=# '"' && l:cur_char !=# "'"
            let l:extra_chars += 1
            let l:cur_char = getline(a:lnum)[l:pos_start_string[1]
                        \ + l:extra_chars]
        endwhile


        if l:cur_char ==# '"'
            call feedkeys("a\"\<CR>\"\<esc>", 'n')
        else
            call feedkeys("a'\<CR>'\<esc>", 'n')
        endif
    elseif l:breakpoint[1] > indent(a:lnum)
        call winrestview(l:breakpointview)

        let l:next_char = getline(a:lnum)[l:breakpoint[1]]
        if l:next_char ==# '{' || l:next_char ==# '(' || l:next_char ==# '['
            "Add a newline after the bracket
            call feedkeys("la\<CR>\<esc>", 'n')
        elseif !s:isBetweenBrackets(l:breakpointview)
            "Add a bracket when this is not present yet
            call winrestview(l:breakpointview)
            call feedkeys("a(\<esc>", 'n')
        else
            "Otherwise fall back to a backslash
            call winrestview(l:breakpointview)
            call feedkeys("a\\\<CR>\<esc>", 'n')
        endif
    else
        call cursor(a:lnum, l:twplus1)
        "Search for a space that is not trailing whitespace
        let l:afterbreakpoint = s:SearchPosWithSkip(' [^ ]', 'cW', s:skip_string, a:lnum)

        if l:afterbreakpoint[0] != 0
            call feedkeys("r\<CR>", 'n')
        else
            "echom 'fallling back to old method'
            call winrestview(l:winview)
            return 1
        endif
    endif
  endif

  call feedkeys('gqq', 'n')
endfunction

function s:isBetweenBrackets(winview)
  " Check if match is inside brackets
  let l:skip = s:skip_string
  return s:isBetweenPair('(', ')', a:winview, l:skip)
    \ || s:isBetweenPair('{', '}', a:winview, l:skip)
    \ || s:isBetweenPair('\[', '\]', a:winview, l:skip)
endfunction

function s:isBetweenPair(left, right, winview, skip)
  call winrestview(a:winview)
  let l:bracket = searchpairpos(a:left, '', a:right, 'bW', a:skip)
  return l:bracket[0] != 0
endfunction

function s:VirtcolToCol(lnum, cnum)
    let l:last = virtcol([a:lnum, '$'])
    let l:cnum = a:cnum
    let l:vcol = virtcol([a:lnum, l:cnum])
    while l:vcol <= a:cnum && l:vcol < l:last
        let l:cnum += 1
        let l:vcol = virtcol([a:lnum, l:cnum])
    endwhile
    return l:cnum - 1
endfunction
