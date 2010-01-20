require 'spec_helper'
require 'cli'

describe EY::CLI do
  it "has a CommandNotFound error" do
    EY::CLI::CommandNotFound.ancestors.should include(Exception)
  end

  describe "command_to_class method" do
    context "given a command with a class" do
      it "returns that class" do
        EY::CLI.command_to_class("help").should == EY::CLI::Help
      end
    end

    context "given a command without a class" do
      it "raises CommandNotFound" do
        lambda {
          EY::CLI.command_to_class("frobnick")
        }.should raise_error(EY::CLI::CommandNotFound)
      end
    end
  end

  describe "usage method" do
    it "prints usage instructions" do
      capture_stderr { EY::CLI.usage }.should include("usage")
    end

    it "prints usage for each command" do
      usage = capture_stderr { EY::CLI.usage }
      EY::CLI::COMMANDS.values.each do |c|
        usage.should include(c.short_usage)
      end
    end
  end

end # EY::CLI
