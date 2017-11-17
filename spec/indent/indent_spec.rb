require "spec_helper"

shared_examples_for "vim" do

  before(:each) {
    # clear buffer
    vim.normal 'gg"_dG'

    # Insert two blank lines.
    # The first line is a corner case in this plugin that would shadow the
    # correct behaviour of other tests. Thus we explicitly jump to the first
    # line when we require so.
    vim.feedkeys 'i\<CR>\<CR>\<ESC>'
  }

  describe "when using the indent plugin" do
    it "sets the indentexpr and indentkeys options" do
      vim.command("set indentexpr?").should include "GetPythonPEPIndent("
      vim.command("set indentkeys?").should include "=elif"
    end

    it "sets autoindent and expandtab" do
      vim.command("set autoindent?").should match(/\s*autoindent/)
      vim.command("set expandtab?").should match(/\s*expandtab/)
    end
  end

  describe "when entering the first line" do
    before { vim.feedkeys '0ggipass' }

    it "does not indent" do
      indent.should == 0
      proposed_indent.should == 0
    end

    it "does not indent when using '=='" do
      vim.normal "=="
      indent.should == 0
    end
  end

  describe "when after a '(' that is at the end of its line" do
    before { vim.feedkeys 'itest(\<CR>' }

    it "indents by one level" do
      proposed_indent.should == shiftwidth
      vim.feedkeys 'something'
      indent.should == shiftwidth
      vim.normal '=='
      indent.should == shiftwidth
    end

    it "puts the closing parenthesis at the same level" do
      vim.feedkeys ')'
      indent.should == 0
    end
  end

  describe "when after an '(' that is followed by something" do
    before { vim.feedkeys 'itest(something,\<CR>' }

    it "lines up on following lines" do
      indent.should == 5
      vim.feedkeys 'more,\<CR>'
      indent.should == 5
    end

    it "lines up the closing parenthesis" do
      vim.feedkeys ')'
      indent.should == 5
    end

    it "does not touch the closing parenthesis if it is already indented further" do
      vim.feedkeys '  )'
      indent.should == 7
    end
  end

  describe "when after an '{' that is followed by a comment" do
    before { vim.feedkeys 'imydict = {  # comment\<CR>' }

    it "indent by one level" do
      indent.should == shiftwidth
      vim.feedkeys '1: 1,\<CR>'
      indent.should == shiftwidth
    end

    it "lines up the closing parenthesis" do
      vim.feedkeys '}'
      indent.should == 0
    end
  end

  describe "when using gq to reindent a '(' that is" do
    before { vim.feedkeys 'itest(' }
    it "something and has a string without spaces at the end" do
      vim.feedkeys 'something_very_long_blaaaaaaaaa, "some_very_long_string_blaaaaaaaaaaaaaaaaaaaa"\<esc>gqq'
      indent.should == 5
    end
  end

  describe "when after multiple parens of different types" do
    it "indents by one level" do
      vim.feedkeys 'if({\<CR>'
      indent.should == shiftwidth
    end

    it "lines up with the last paren" do
      vim.feedkeys 'ifff({123: 456,\<CR>'
      indent.should == 5
    end
  end

  describe "when '#' is contained in a string that is followed by a colon" do
    it "indents by one level" do
        vim.feedkeys 'iif "some#thing" == "test":#test\<CR>pass'
        indent.should == shiftwidth
    end
  end

  describe "when '#' is not contained in a string and is followed by a colon" do
    it "does not indent" do
        vim.feedkeys 'iif "some#thing" == "test"#:test\<CR>'
        indent.should == 0
    end
  end

  describe "when inside an unfinished string" do
    it "does not indent" do
      vim.feedkeys 'i"test:\<ESC>'
      vim.echo('synIDattr(synID(line("."), col("."), 0), "name")'
              ).downcase.should include 'string'
      vim.feedkeys 'a\<CR>'
      proposed_indent.should == 0
      indent.should == 0
    end

    it "does not dedent" do
      vim.feedkeys 'iif True:\<CR>"test:\<ESC>'
      vim.echo('synIDattr(synID(line("."), col("."), 0), "name")'
              ).downcase.should include 'string'
      proposed_indent.should == shiftwidth
      indent.should == shiftwidth
    end
  end

  describe "when the previous line has a colon in a string" do
    before { vim.feedkeys 'itest(":".join(["1","2"]))\<CR>' }
    it "does not indent" do
      vim.feedkeys 'if True:'
      indent.should == 0
      proposed_indent.should == 0
    end
  end

  describe "when the previous line has a list slice" do
    it "does not indent" do
      vim.feedkeys 'ib = a[2:]\<CR>'
      indent.should == 0
      proposed_indent.should == 0
    end
  end

  describe "when line is empty inside a block" do
    it "is indented like the previous line" do
      vim.feedkeys 'idef a():\<CR>1\<CR>\<CR>2\<ESC>kcc'
      indent.should == shiftwidth
    end
  end

  describe "when an empty line is after empty line / before non-empty" do
    it "is indented like the next line" do
      vim.feedkeys 'idef a():\<CR>1\<CR>\<CR>\<CR>2\<ESC><<kcc'
      indent.should == 0
    end
  end

  describe "when an empty line is after empty line / before non-empty (nested)" do
    it "is indented like the next line" do
      vim.feedkeys 'idef a():\<CR>1\<CR>\<CR>\<CR>\<ESC>0i\<TAB>2\<ESC>kcc'
      indent.should == shiftwidth
    end
  end

  describe "when line is empty inside a block following multi-line statement" do
    it "is indented like the previous line" do
      vim.feedkeys 'idef a():\<CR>x = (1 +\<CR>2)\<CR>\<CR>y\<ESC>kcc'
      indent.should == shiftwidth
    end
  end

  describe "when line is empty inside a block following stop statement" do
    it "is indented like the previous line minus shiftwidth" do
      vim.feedkeys 'iif x:\<CR>if y:\<CR>pass\<CR>\<CR>z\<ESC>kcc'
      indent.should == shiftwidth
    end
  end

  describe "when using simple control structures" do
      it "indents shiftwidth spaces" do
          vim.feedkeys 'iwhile True:\<CR>pass'
          indent.should == shiftwidth
      end
  end

  describe "when using a function definition" do
      it "indents shiftwidth spaces" do
          vim.feedkeys 'idef long_function_name(\<CR>arg'
          indent.should == shiftwidth * 2
      end
  end

  describe "when using a class definition" do
      it "indents shiftwidth spaces" do
          vim.feedkeys 'iclass Foo(\<CR>'
          indent.should == shiftwidth * 2
      end
  end

  describe "when writing an 'else' block" do
    it "aligns to the preceeding 'for' block" do
      vim.feedkeys 'ifor x in "abc":\<CR>pass\<CR>else:'
      indent.should == 0
    end

    it "aligns to the preceeding 'if' block" do
      vim.feedkeys 'ifor x in "abc":\<CR>if True:\<CR>pass\<CR>else:'
      indent.should == shiftwidth
    end
  end

  describe "when using parens and control statements" do
    it "avoids ambiguity by using extra indentation" do
      vim.feedkeys 'iif (111 and\<CR>'
      if shiftwidth == 4
        indent.should == shiftwidth * 2
      else
        indent.should == 4
      end
      vim.feedkeys '222):\<CR>'
      indent.should == shiftwidth
      vim.feedkeys 'pass\<CR>'
      indent.should == 0
    end

    it "still aligns parens properly if not ambiguous" do
      vim.feedkeys 'iwhile (111 and\<CR>'
      indent.should == 7
      vim.feedkeys '222):\<CR>'
      indent.should == shiftwidth
      vim.feedkeys 'pass\<CR>'
      indent.should == 0
    end

    it "still handles multiple parens correctly" do
      vim.feedkeys 'iif (111 and (222 and 333\<CR>'
      indent.should == 13
      vim.feedkeys 'and 444\<CR>'
      indent.should == 13
      vim.feedkeys ')\<CR>'
      if shiftwidth == 4
        indent.should == shiftwidth * 2
      else
        indent.should == 4
      end
      vim.feedkeys 'and 555):\<CR>'
      indent.should == shiftwidth
      vim.feedkeys 'pass\<CR>'
      indent.should == 0
    end
  end

  describe "when a line breaks with a manual '\\'" do
    it "indents shiftwidth spaces on normal line" do
        vim.feedkeys 'ivalue = test + \\\\\<CR>'
        indent.should == shiftwidth
    end

    it "indents 2x shiftwidth spaces for control structures" do
        vim.feedkeys 'iif somevalue == xyz and \\\\\<CR>'
        indent.should == shiftwidth * 2
    end

    it "indents relative to line above" do
        vim.feedkeys 'i\<TAB>value = test + \\\\\<CR>'
        indent.should == shiftwidth * 2
    end
  end

  describe "when current line is dedented compared to previous line" do
     before { vim.feedkeys 'i\<TAB>\<TAB>if x:\<CR>y = True\<CR>\<ESC>' }
     it "and current line has a valid indentation (Part 1)" do
        vim.feedkeys '0i\<TAB>if y:'
        proposed_indent.should == -1
     end

     it "and current line has a valid indentation (Part 2)" do
        vim.feedkeys '0i\<TAB>\<TAB>if y:'
        proposed_indent.should == -1
     end

     it "and current line has an invalid indentation" do
        vim.feedkeys 'i    while True:\<CR>'
        indent.should == previous_indent + shiftwidth
     end
  end

  describe "when current line is dedented compared to the last non-empty line" do
     before { vim.feedkeys 'i\<TAB>\<TAB>if x:\<CR>y = True\<CR>\<CR>\<ESC>' }
     it "and current line has a valid indentation" do
        vim.feedkeys '0i\<TAB>if y:'
        proposed_indent.should == -1
     end
  end

  describe "when an 'if' is followed by" do
     before { vim.feedkeys 'i\<TAB>\<TAB>if x:\<CR>' }
     it "an elif, it lines up with the 'if'" do
        vim.feedkeys 'elif y:'
        indent.should == shiftwidth * 2
     end

     it "an 'else', it lines up with the 'if'" do
        vim.feedkeys 'else:'
        indent.should == shiftwidth * 2
     end
  end

  describe "when an 'if' contains a try-except" do
     before {
       vim.feedkeys 'iif x:\<CR>try:\<CR>pass\<CR>except:\<CR>pass\<CR>'
       indent.should == shiftwidth
     }
     it "an 'else' should be indented to the try" do
       vim.feedkeys 'else:'
       indent.should == shiftwidth
       proposed_indent.should == shiftwidth
     end
     it "an 'else' should keep the indent of the 'if'" do
       vim.feedkeys 'else:\<ESC><<'
       indent.should == 0
       proposed_indent.should == 0
     end
  end

  describe "when a 'for' is followed by" do
     before { vim.feedkeys 'i\<TAB>\<TAB>for x in y:\<CR>' }
     it "an 'else', it lines up with the 'for'" do
        vim.feedkeys 'else:'
        indent.should == shiftwidth * 2
     end
  end

  describe "when an 'else' is followed by" do
     before { vim.feedkeys 'i\<TAB>\<TAB>else:\<CR>XXX\<CR>' }
     it "a 'finally', it lines up with the 'else'" do
        vim.feedkeys 'finally:'
        indent.should == shiftwidth * 2
     end
  end


  describe "when a 'try' is followed by" do
     before { vim.feedkeys 'i\<TAB>\<TAB>try:\<CR>' }
     it "an 'except', it lines up with the 'try'" do
        vim.feedkeys 'except:'
        indent.should == shiftwidth * 2
     end

     it "an 'else', it lines up with the 'try'" do
        vim.feedkeys 'else:'
        indent.should == shiftwidth * 2
     end

     it "a 'finally', it lines up with the 'try'" do
        vim.feedkeys 'finally:'
        indent.should == shiftwidth * 2
     end
  end

  describe "when an 'except' is followed by" do
     before { vim.feedkeys 'i\<TAB>\<TAB>except:\<CR>' }
     it "an 'else', it lines up with the 'except'" do
        vim.feedkeys 'else:'
        indent.should == shiftwidth * 2
     end

     it "another 'except', it lines up with the previous 'except'" do
        vim.feedkeys 'except:'
        indent.should == shiftwidth * 2
     end

     it "a 'finally', it lines up with the 'except'" do
        vim.feedkeys 'finally:'
        indent.should == shiftwidth * 2
     end
  end

  describe "when an else is used inside of a nested if" do
    before { vim.feedkeys 'iif foo:\<CR>\<TAB>if bar:\<CR>\<TAB>\<TAB>pass\<CR>' }
    it "indents an else to the inner if" do
      vim.feedkeys 'else:'
      indent.should == shiftwidth * 2
    end
  end

  describe "when jedi-vim call signatures are used" do
    before { vim.command 'syn match jediFunction "JEDI_CALL_SIGNATURE" keepend extend' }

    it "ignores the call signature after a colon" do
      vim.feedkeys 'iif True:  JEDI_CALL_SIGNATURE\<CR>'
      indent.should == shiftwidth
    end

    it "ignores the call signature after a function" do
      vim.feedkeys 'idef f(  JEDI_CALL_SIGNATURE\<CR>'
      indent.should == shiftwidth * 2
    end
  end
end

shared_examples_for "multiline strings" do
  before(:each) {
    # clear buffer
    vim.normal 'gg"_dG'

    # Insert two blank lines.
    # The first line is a corner case in this plugin that would shadow the
    # correct behaviour of other tests. Thus we explicitly jump to the first
    # line when we require so.
    vim.feedkeys 'i\<CR>\<CR>\<ESC>'
  }

  describe "when after an '(' that is followed by an unfinished string" do
    before { vim.feedkeys 'itest("""' }

    it "it indents the next line" do
      vim.feedkeys '\<CR>'
      expected_proposed, expected_indent = multiline_indent(0, shiftwidth)
      proposed_indent.should == expected_proposed
      indent.should == expected_indent
    end

    it "with contents it indents the second line to the parenthesis" do
      vim.feedkeys 'second line\<CR>'
      expected_proposed, expected_indent = multiline_indent(0, 5)
      proposed_indent.should == expected_proposed
      indent.should == expected_indent
    end
  end

  describe "when after assigning an unfinished string" do
    before { vim.feedkeys 'itest = """' }

    it "it indents the next line" do
      vim.feedkeys '\<CR>'
      expected_proposed, expected_indent = multiline_indent(0, shiftwidth)
      proposed_indent.should == expected_proposed
      indent.should == expected_indent
    end
  end

  describe "when after assigning an unfinished string" do
    before { vim.feedkeys 'i    test = """' }

    it "it indents the next line" do
      vim.feedkeys '\<CR>'
      expected_proposed, expected_indent = multiline_indent(4, shiftwidth + 4)
      proposed_indent.should == expected_proposed
      indent.should == expected_indent
    end
  end

  describe "when after assigning a finished string" do
    before { vim.feedkeys 'i    test = ""' }

    it "it does indent the next line" do
      vim.feedkeys '\<CR>'
      indent.should == 4
    end

    it "and writing a new string, it does indent the next line" do
      vim.feedkeys '\<CR>""'
      indent.should == 4
    end
  end

  describe "when after a docstring" do
    before { vim.feedkeys 'i    """' }
    it "it does indent the next line to the docstring" do
      vim.feedkeys '\<CR>'
      indent.should == 4
      proposed_indent.should == 4
    end
  end

  describe "when after a docstring with contents" do
    before { vim.feedkeys 'i    """First line' }
    it "it does indent the next line to the docstring" do
      vim.feedkeys '\<CR>'
      indent.should == 4
      proposed_indent.should == 4
    end
  end

  describe "when breaking a string after opening parenthesis" do
    before { vim.feedkeys 'i    foo("""bar<Left><Left><Left>' }
    it "it does indent the next line as after an opening multistring" do
      vim.feedkeys '\<CR>'
      expected_proposed, expected_indent = multiline_indent(4, 4 + shiftwidth)
      indent.should == expected_indent
      proposed_indent.should == expected_proposed
    end
  end
end

describe "vim when using width of 4" do
  before {
    vim.command("set sw=4 ts=4 sts=4 et")
  }
  it_behaves_like "vim"
end

describe "vim when using width of 3" do
  before {
    vim.command("set sw=3 ts=3 sts=3 et")
  }
  it_behaves_like "vim"
end

describe "vim when not using python_pep8_indent_multiline_string" do
  before {
    vim.command("set sw=4 ts=4 sts=4 et")
    vim.command("unlet! g:python_pep8_indent_multiline_string")
  }
  it_behaves_like "multiline strings"
end

describe "vim when using python_pep8_indent_multiline_first=0" do
  before {
    vim.command("set sw=4 ts=4 sts=4 et")
    vim.command("let g:python_pep8_indent_multiline_string=0")
  }
  it_behaves_like "multiline strings"
end

describe "vim when using python_pep8_indent_multiline_string=-1" do
  before {
    vim.command("set sw=4 ts=4 sts=4 et")
    vim.command("let g:python_pep8_indent_multiline_string=-1")
  }
  it_behaves_like "multiline strings"
end

describe "vim when using python_pep8_indent_multiline_string=-2" do
  before {
    vim.command("set sw=4 ts=4 sts=4 et")
    vim.command("let g:python_pep8_indent_multiline_string=-2")
  }
  it_behaves_like "multiline strings"
end

describe "vim for cython" do
  before {
    vim.command "enew"
    vim.command "set ft=cython"
    vim.command "runtime indent/python.vim"

    # Insert two blank lines.
    # The first line is a corner case in this plugin that would shadow the
    # correct behaviour of other tests. Thus we explicitly jump to the first
    # line when we require so.
    vim.feedkeys 'i\<CR>\<CR>\<ESC>'
  }

  describe "when using a cdef function definition" do
      it "indents shiftwidth spaces" do
          vim.feedkeys 'icdef long_function_name(\<CR>arg'
          indent.should == shiftwidth * 2
      end
  end

  describe "when using a cpdef function definition" do
      it "indents shiftwidth spaces" do
          vim.feedkeys 'icpdef long_function_name(\<CR>arg'
          indent.should == shiftwidth * 2
      end
  end
end

describe "Handles far away opening parens" do
  before { vim.feedkeys '\<ESC>ggdGifrom foo import (' }

  it "indents by one level" do
    vim.feedkeys '\<CR>'
    proposed_indent.should == shiftwidth
  end

  it "indents by one level for 10 lines" do
    vim.command('set paste | exe "norm 9o" | set nopaste')
    vim.feedkeys '\<Esc>o'
    indent.should == shiftwidth
  end

  it "indents by one level for 50 lines" do
    vim.command('set paste | exe "norm 49o" | set nopaste')
    vim.feedkeys '\<Esc>o'
    indent.should == shiftwidth
  end
end

describe "Handles far away opening square brackets" do
  before { vim.feedkeys '\<ESC>ggdGibar = [' }

  it "indents by one level" do
    vim.feedkeys '\<CR>'
    proposed_indent.should == shiftwidth
  end

  it "indents by one level for 10 lines" do
    vim.command('set paste | exe "norm 9o" | set nopaste')
    vim.feedkeys '\<Esc>o'
    indent.should == shiftwidth
  end

  it "indents by one level for 100 lines" do
    vim.command('set paste | exe "norm 99o" | set nopaste')
    vim.feedkeys '\<Esc>o'
    indent.should == shiftwidth
  end
end

describe "Handles far away opening curly brackets" do
  before { vim.feedkeys '\<ESC>ggdGijson = {' }

  it "indents by one level" do
    vim.feedkeys '\<CR>'
    vim.feedkeys '\<Esc>o'
    proposed_indent.should == shiftwidth
  end

  it "indents by one level for 10 lines" do
    vim.command('set paste | exe "norm 9o" | set nopaste')
    vim.feedkeys '\<Esc>o'
    indent.should == shiftwidth
  end

  it "indents by one level for 1000 lines" do
    vim.command('set paste | exe "norm 999o" | set nopaste')
    vim.feedkeys '\<Esc>o'
    indent.should == shiftwidth
  end
end

describe "Compact multiline dict" do
  before { vim.feedkeys '\<ESC>ggdGid = {"one": 1,' }

  it "gets indented correctly" do
    vim.feedkeys '\<CR>'
    proposed_indent.should == 5

    vim.feedkeys '"two": 2}'
    proposed_indent.should == 5

    vim.feedkeys '\<CR>'
    proposed_indent.should == 0
  end
end
