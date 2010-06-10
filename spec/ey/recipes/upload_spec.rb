require 'spec_helper'

describe "ey recipes upload" do
  given "integration"

  def command_to_run(opts)
    "recipes upload #{opts[:env]}"
  end

  it_should_behave_like "it takes an environment name"
end

describe "ey recipes upload" do
  given "integration"

  define_git_repo('+cookbooks') do |git_dir|
    git_dir.join("cookbooks").mkdir
    File.open(git_dir.join("cookbooks/file"), "w"){|f| f << "boo" }
  end

  use_git_repo('+cookbooks')

  it "posts the recipes to the correct url" do
    api_scenario "one app, one environment"
    ey "recipes upload giblets", :debug => true

    @out.should =~ /Recipes uploaded successfully for giblets/i
  end

  it "can infer the environment from the current application" do
    api_scenario "one app, one environment"

    ey "recipes upload", :debug => true
    @out.should =~ /Recipes uploaded successfully for giblets/i
  end

  it "complains when it can't infer the environment from the current application" do
    api_scenario "one app, one environment, not linked"

    ey "recipes upload", :debug => true, :expect_failure => true
    @err.should =~ /single environment/i
  end
end
