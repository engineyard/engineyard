require 'spec_helper'

describe "ey recipes upload" do
  it_should_behave_like "an integration test"

  define_git_repo('+cookbooks') do |git_dir|
    git_dir.join("cookbooks").mkdir
    File.open(git_dir.join("cookbooks/file"), "w"){|f| f << "boo" }
    system("git add .")
    system("git commit -q -m 'First Commit'")
  end

  use_git_repo('+cookbooks')

  it "posts the recipes to the correct url" do
    api_scenario "one app, one environment"
    ey "recipes upload giblets", :debug => true

    @out.should =~ /recipes uploaded successfully/i
  end

  it "errors correctly on bogus env name" do
    api_scenario "one app, one environment"
    ey "recipes upload bogusenv", :expect_failure => true

    @err.should =~ /No environment named 'bogusenv'/
  end

  it "can infer the environment from the current application" do
    api_scenario "one app, one environment"

    ey "recipes upload", :debug => true
    @out.should =~ /recipes uploaded successfully/i
  end

  it "complains when it can't infer the environment from the current application" do
    api_scenario "one app, one environment, not linked"

    ey "recipes upload", :debug => true, :expect_failure => true
    @err.should =~ /single environment/i
  end
end
