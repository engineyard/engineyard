require 'spec_helper'

describe "ey web enable" do
  given "integration"

  def command_to_run(opts)
    cmd = %w[web enable]
    cmd << "-e" << opts[:environment] if opts[:environment]
    cmd << "-a" << opts[:app]         if opts[:app]
    cmd << "-c" << opts[:account]     if opts[:account]
    cmd << "--verbose"                if opts[:verbose]
    cmd
  end

  def verify_ran(scenario)
    @ssh_commands.should have_command_like(/engineyard-serverside.*disable_maintenance.*--app #{scenario[:application]}/)
  end

  include_examples "it takes an environment name and an app name and an account name"
  include_examples "it invokes engineyard-serverside"

  it "fails when given a bad option" do
    ey %w[web enable --lots --of --bogus --options], :expect_failure => true
    @err.should include("Unknown switches")
  end
end
