require 'vimrunner'
require 'vimrunner/rspec'

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  config.start_vim do
    vim = Vimrunner.start

    plugin_path = File.expand_path('../..', __FILE__)

    # add_plugin appends the path to the rtp... :(
    # vim.add_plugin(plugin_path, 'indent/python.vim')

    vim.command "set rtp^=#{plugin_path}"
    vim.command "runtime indent/python.vim"

    vim
  end
end
