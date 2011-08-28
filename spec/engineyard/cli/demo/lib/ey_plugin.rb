require 'engineyard/cli/command_manager'
require 'engineyard/thor'

# the symbol which will be converted to class name to be evaluated (EY::CLI::FooBar for :foo_bar) and the path to that file/task.
EY::CLI::CommandManager.register_class "demo", File.expand_path(File.join(File.dirname(__FILE__), "demo.rb"))
