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

    vim
  end
end
