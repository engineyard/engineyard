require 'spec_helper'

describe "ey web restart" do
  given "integration"

  def command_to_run(opts)
    cmd = %w[web restart]
    cmd << "-e" << opts[:environment] if opts[:environment]
    cmd << "-a" << opts[:app]         if opts[:app]
    cmd << "-c" << opts[:account]     if opts[:account]
    cmd << "--verbose"                if opts[:verbose]
    cmd
  end

  def verify_ran(scenario)
    @ssh_commands.should have_command_like(/engineyard-serverside.*restart.*--app #{scenario[:application]}/)
  end

  include_examples "it takes an environment name and an app name and an account name"
  include_examples "it invokes engineyard-serverside"
end
