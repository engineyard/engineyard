require 'spec_helper'

describe "ey web disable" do
  given "integration"

  use_git_repo('default')

  before(:all) do
    api_scenario "one app, one environment"
  end

  it "tells eysd to put up the maintenance page" do
    ey "web disable"
    @ssh_commands.should have_command_like(/eysd deploy enable_maintenance_page --app rails232app/)
  end
end

describe "ey web disable" do
  given "integration"

  def command_to_run(opts)
    "web disable #{opts[:env]}"
  end

  it_should_behave_like "it takes an environment name"
end
