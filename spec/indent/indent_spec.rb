require "spec_helper"

describe "vim" do

  before(:each) { vim.normal 'gg"_dG' }  # clear buffer

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
    before { vim.feedkeys 'ipass' }

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

  describe "when using simple control structures" do
      it "indents shiftwidth spaces" do
          vim.feedkeys 'iwhile True:\<CR>pass'
          indent.should == shiftwidth
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
        vim.feedkeys 'i\tvalue = test + \\\\\<CR>'
        indent.should == shiftwidth * 2
    end
  end

  describe "when current line is dedented compared to previous line" do
     before { vim.feedkeys 'i\<TAB>\<TAB>if x:\<CR>return True\<CR>\<ESC>' }
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

