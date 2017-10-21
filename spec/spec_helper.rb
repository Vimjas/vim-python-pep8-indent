require 'vimrunner'
require 'vimrunner/rspec'

# Explicitly enable usage of "should".
RSpec.configure do |config|
    config.expect_with(:rspec) { |c| c.syntax = :should }
end

Vimrunner::RSpec.configure do |config|
  # Use a single Vim instance for the test suite. Set to false to use an
  # instance per test (slower, but can be easier to manage).
  # This requires using gvim, otherwise it hangs after a few tests.
  config.reuse_server = ENV['VIMRUNNER_REUSE_SERVER'] == '1' ? true : false

  config.start_vim do
    vim = config.reuse_server ? Vimrunner.start_gvim : Vimrunner.start
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
    def hang_closing
      i = vim.echo("get(g:, 'python_pep8_indent_hang_closing', 0)").to_i
      return (i != 0)
    end
    def set_hang_closing(value)
      if value.nil?
        vim.command("unlet! g:python_pep8_indent_hang_closing")
      else
        i = value ? 1 : 0
        vim.command("let g:python_pep8_indent_hang_closing=#{i}")
      end
    end

    vim
  end
end
