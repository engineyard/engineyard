require 'spec_helper'

describe "ey web disable" do
  given "integration"

  def command_to_run(opts)
    cmd = "web disable"
    cmd << " -e #{opts[:env]}" if opts[:env]
    cmd
  end

  def verify_ran(scenario)
    @ssh_commands.should have_command_like(/eysd deploy enable_maintenance_page --app #{scenario[:application]}/)
  end

  it_should_behave_like "it takes an environment name"
  it_should_behave_like "it invokes eysd"
end
