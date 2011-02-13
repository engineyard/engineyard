require 'spec_helper'
require 'net/ssh'

describe "ey cron lists current cron configuration" do
  given "integration"

  def command_to_run(opts)
    cmd = "cron"
    cmd << " -e #{opts[:environment]}" if opts[:environment]
    cmd << " -a #{opts[:app]}" if opts[:app]
    cmd << " -c #{opts[:account]}" if opts[:account]
    cmd << " --verbose" if opts[:verbose]
    cmd
  end

  def verify_ran(scenario)
    @out.should match(/Cron for #{scenario[:environment]}/)
    @out.should match(/Minute   Hour   Day of Month       Month          Day of Week        Command/)
  end

  it_should_behave_like "it takes an environment name and an app name and an account name"
end
