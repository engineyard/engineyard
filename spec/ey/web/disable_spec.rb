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
    expect(@ssh_commands).to have_command_like(/engineyard-serverside.*enable_maintenance.*--app #{scenario[:application]}/)
  end

  include_examples "it takes an environment name and an app name and an account name"
  include_examples "it invokes engineyard-serverside"
end
