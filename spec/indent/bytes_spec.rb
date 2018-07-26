require "spec_helper"

describe "handles byte strings" do
  before(:all) {
      vim.command 'syn region pythonBytes start=+[bB]"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonBytesError,pythonBytesContent,@Spell'
  }

  before(:each) {
    # clear buffer
    vim.normal 'gg"_dG'

    # Insert two blank lines.
    # The first line is a corner case in this plugin that would shadow the
    # correct behaviour of other tests. Thus we explicitly jump to the first
    # line when we require so.
    vim.feedkeys 'i\<CR>\<CR>\<ESC>'
  }

  it "it does not indent to bracket in byte string" do
    vim.feedkeys 'ireg = b"["\<Esc>'
    vim.echo('map(synstack(line("."), col(".")), "synIDattr(v:val, \"name\")")'
            ).should == "['pythonBytes']"
    vim.feedkeys 'o'
    indent.should == 0
  end
end
