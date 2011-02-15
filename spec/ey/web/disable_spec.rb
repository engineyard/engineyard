require 'spec_helper'

describe "ey web disable" do
  given "integration"

  def command_to_run(opts)
    cmd = %w[web disable]
    cmd << "-e" << opts[:environment] if opts[:environment]
    cmd << "-a" << opts[:app]         if opts[:app]
    cmd << "-c" << opts[:account]     if opts[:account]
    cmd << "--verbose"                if opts[:verbose]
    cmd
  end

  def verify_ran(scenario)
    @ssh_commands.should have_command_like(/engineyard-serverside.*deploy enable_maintenance_page.*--app #{scenario[:application]}/)
  end

  it_should_behave_like "it takes an environment name and an app name and an account name"
  it_should_behave_like "it invokes engineyard-serverside"
end
