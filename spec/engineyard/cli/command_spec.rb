require 'spec_helper'
require 'cli'

describe EY::CLI::Command do
  before(:each){ @c = EY::CLI::Command }

  it "should track a list of its descendents" do
    class Foo < EY::CLI::Command; end
    @c.commands.should include(Foo)
    Object.send(:remove_const, :Foo)
  end

  it "should not have a run method" do
    lambda { @c.run("foo") }.should raise_error(RuntimeError)
  end

  it "should not have a short usage method" do
    lambda { @c.short_usage }.should raise_error(RuntimeError)
  end
end # EY::CLI::Command
