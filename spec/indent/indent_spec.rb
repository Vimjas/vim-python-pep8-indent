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
      proposed_indent.should == 0
      indent.should == 0
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

  describe "when after an '(' that is followed by an unfinished string" do
    before { vim.feedkeys 'itest("""' }

    it "it does not indent the next line" do
      vim.feedkeys '\<CR>'
      proposed_indent.should == 0
      indent.should == 0
    end

    it "with contents it does not indent the next line" do
      vim.feedkeys 'string_contents\<CR>'
      proposed_indent.should == 0
      indent.should == 0
    end
  end

  describe "when after assigning an unfinished string" do
    before { vim.feedkeys 'itest = """' }

    it "it does not indent the next line" do
      vim.feedkeys '\<CR>'
      proposed_indent.should == 0
      indent.should == 0
    end
  end

  describe "when after assigning an unfinished string" do
    before { vim.feedkeys 'i    test = """' }

    it "it does not indent the next line" do
      vim.feedkeys '\<CR>'
      proposed_indent.should == 0
      indent.should == 0
    end
  end

  describe "when after assigning a finished string" do
    before { vim.feedkeys 'i    test = ""' }

    it "it does indent the next line" do
      vim.feedkeys '\<CR>'
      proposed_indent.should == 4
      indent.should == 4
    end

    it "and writing a new string, it does indent the next line" do
      vim.feedkeys '\<CR>""'
      proposed_indent.should == 4
      indent.should == 4
    end
  end

  describe "when after a docstring" do
    before { vim.feedkeys 'i    """' }

    it "it does indent the next line" do
      vim.feedkeys '\<CR>'
      proposed_indent.should == 4
      indent.should == 4
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

  def shiftwidth
    @shiftwidth ||= vim.echo("exists('*shiftwidth') ? shiftwidth() : &sw").to_i
  end
  def tabstop
    @tabstop ||= vim.echo("&tabstop").to_i
  end
  def indent
    vim.echo("indent('.')").to_i
  end
  def previous_indent
    pline = vim.echo("line('.')").to_i - 1
    vim.echo("indent('#{pline}')").to_i
  end
  def proposed_indent
    line = vim.echo("line('.')")
    col = vim.echo("col('.')")
    indent_value = vim.echo("GetPythonPEPIndent(line('.'))").to_i
    vim.command("call cursor(#{line}, #{col})")
    return indent_value
  end
end

describe "vim when using width of 4" do
  before {
    vim.command("set sw=4 ts=4 sts=4 et")
  }

  it_behaves_like "vim"
end

describe "vim when using width of 8" do
  before {
    vim.command("set sw=8 ts=8 sts=8 et")
  }

  it_behaves_like "vim"
end
