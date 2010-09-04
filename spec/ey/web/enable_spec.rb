require 'spec_helper'

describe "ey web enable" do
  given "integration"

  def command_to_run(opts)
    cmd = "web enable"
    cmd << " -e #{opts[:env]}" if opts[:env]
    cmd << " -a #{opts[:app]}" if opts[:app]
    cmd << " -c #{opts[:account]}" if opts[:account]
    cmd << " --verbose" if opts[:verbose]
    cmd
  end

  def verify_ran(scenario)
    @ssh_commands.should have_command_like(/engineyard-serverside.*deploy disable_maintenance_page.*--app #{scenario[:application]}/)
  end

  it_should_behave_like "it takes an environment name and an app name and an account name"
  it_should_behave_like "it invokes engineyard-serverside"
end
