require 'spec_helper'
require 'net/ssh'

describe "ey cron lists current cron configuration" do
  given "integration"

  def command_to_run(opts)
    cmd = "cron list"
    cmd << " -e #{opts[:environment]}" if opts[:environment]
    cmd << " -c #{opts[:account]}" if opts[:account]
    cmd << " --verbose" if opts[:verbose]
    cmd
  end

  def verify_ran(scenario)
    @out.should match(/Cron for #{scenario[:environment]}/)
    @out.should match(/Minute   Hour   Day of Month       Month          Day of Week        Command/)
  end

  it_should_behave_like "it takes an environment name and an account name"
end

describe "ey cron add adds complex cron configuration for deploy user" do
  given "integration"

  def command_to_run(opts)
    cmd = "cron add 'complex hourly' '/path/to/some/command' '0 * * * *'"
    cmd << " -e #{opts[:environment]}" if opts[:environment]
    cmd << " -c #{opts[:account]}" if opts[:account]
    cmd << " --verbose" if opts[:verbose]
    cmd
  end

  def verify_ran(scenario)
    @out.should match(/Cron added to #{scenario[:environment]}/)
  end

  it_should_behave_like "it takes an environment name and an account name"
end
