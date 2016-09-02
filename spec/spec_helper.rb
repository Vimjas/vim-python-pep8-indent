require 'vimrunner'
require 'vimrunner/rspec'

Vimrunner::RSpec.configure do |config|
  # Use a single Vim instance for the test suite. Set to false to use an
  # instance per test (slower, but can be easier to manage).
  # FIXME: reuse_server = true seems to hang after a certain number of test cases
  #  - Travis CI hangs after 15 successful tests.
  #  - Locally it may hang also, with Vim and Xorg using 100% CPU.
  # Therefore default to false in both cases.
  config.reuse_server = ENV['CI'] ? false : false

  config.start_vim do
    vim = Vimrunner.start

    plugin_path = File.expand_path('../..', __FILE__)

    # add_plugin appends the path to the rtp... :(
    # vim.add_plugin(plugin_path, 'indent/python.vim')

    vim.command "set rtp^=#{plugin_path}"
    vim.command "runtime syntax/python.vim"
    vim.command "runtime indent/python.vim"

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
      indent_value = vim.echo("GetPythonPEPIndent(#{line})").to_i
      vim.command("call cursor(#{line}, #{col})")
      return indent_value
    end
    def multiline_indent(prev, default)
      i = vim.echo("get(g:, 'python_pep8_indent_multiline_string', 0)").to_i
      return (i == -2 ? default : i), i < 0 ? (i == -1 ? prev : default) : i
    end

    vim
  end
end
