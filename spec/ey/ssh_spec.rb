require 'spec_helper'

print_my_args_ssh = "#!/bin/sh\necho ssh $*"

describe "ey ssh" do
  it_should_behave_like "an integration test"

  before(:all) do
    api_scenario "one app, two environments"
  end

  it "SSH-es into the right environment" do
    ey "ssh giblets", :prepend_to_path => {'ssh' => print_my_args_ssh}
    @raw_ssh_commands.should == ["ssh turkey@174.129.198.124"]
  end

  it "complains if it has no app master" do
    ey "ssh bakon", :expect_failure => true
    @err.should =~ /'bakon' does not have a master instance/
  end

  it "complains if you give it a bogus environment" do
    ey "ssh bogusenv", :prepend_to_path => {'ssh' => print_my_args_ssh}, :expect_failure => true
    @raw_ssh_commands.should be_empty
    @err.should =~ /bogusenv/
  end
end

describe "ey ssh" do
  it_should_behave_like "an integration test"

  it "guesses the environment from the current application" do
    api_scenario "one app, one environment"

    ey "ssh", :prepend_to_path => {'ssh' => print_my_args_ssh}
    @raw_ssh_commands.should == ["ssh turkey@174.129.198.124"]
  end

  it "complains when it can't guess the environment and its name isn't specified" do
    api_scenario "one app, one environment, not linked"

    ey "ssh", :prepend_to_path => {'ssh' => print_my_args_ssh}, :expect_failure => true
    @err.should =~ /single environment/i
  end
end

describe "ey ssh ENV" do
  it_should_behave_like "an integration test"

  before(:all) do
    api_scenario "one app, many similarly-named environments"
  end

  it "works when given an unambiguous substring" do
    ey "ssh prod", :prepend_to_path => {'ssh' => print_my_args_ssh}
    @raw_ssh_commands.should == ["ssh turkey@174.129.198.124"]
  end

  it "doesn't require you to be in any app's directory if the name is unambiguous" do
    Dir.chdir(Dir.tmpdir) do
      ey "ssh prod", :prepend_to_path => {'ssh' => print_my_args_ssh}
      @raw_ssh_commands.should == ["ssh turkey@174.129.198.124"]
    end
  end

  it "complains when given an ambiguous substring" do
    ey "ssh staging", :hide_err => true, :expect_failure => true
    @err.should match(/'staging' is ambiguous/)
  end
end
