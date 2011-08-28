require 'spec_helper'
require 'engineyard/cli'
require 'engineyard/cli/command_manager'

describe EY::CLI::CommandManager do
  before(:all) do
    @hardcoded = [ "help", "deploy", "status", "environments", "rebuild", "rollback", "ssh", "logs", "recipes", "web", "version" ]
    @command_manager = EY::CLI::CommandManager
  end

  it "lets Thor manage all of the tasks registered" do
     @command_manager.all_registered_commands.class.should == Thor::CoreExt::OrderedHash 
  end

  it "tracks the commands that are hardcoded in the ey gem code" do
    registered_names = @command_manager.all_registered_commands.map{|task| task.first }
    @hardcoded.each { |h| registered_names.should include h }
  end
  
  it "adds commands" do
    @command_manager.register_class("demo", File.expand_path(File.join(File.dirname(__FILE__), "demo","lib","demo.rb")))
    registered_names = @command_manager.all_registered_commands.map{|task| task.first }
    registered_names.should include "demo"
  end
  
end