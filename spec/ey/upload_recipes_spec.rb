require 'spec_helper'

describe "ey recipes upload" do
  it_should_behave_like "an integration test"

  before(:all) do
    @recipe_dir = Pathname.new("/tmp/#{$$}")
    @recipe_dir.mkdir
    Dir.chdir(@recipe_dir) do
      @recipe_dir.join("cookbooks").mkdir
      File.open(@recipe_dir.join("cookbooks/file"), "w"){|f| f << "boo" }
      `git init`
      `git add .`
      `git commit -m "OMG"`
      `git remote add testremote user@host.tld:path/to/repo.git`
    end
  end

  it "posts the recipes to the correct url" do
    api_scenario "one app, one environment"
    Dir.chdir(@recipe_dir) do
      ey "recipes upload giblets", :debug => true
    end

    @out.should =~ /recipes uploaded successfully/i
  end

  it "errors correctly on bogus env name" do
    api_scenario "one app, one environment"
    ey "recipes upload bogusenv", :expect_failure => true

    @err.should =~ /can't be found/i
  end

  it "can infer the environment from the current application" do
    api_scenario "one app, one environment", "user@host.tld:path/to/repo.git"

    Dir.chdir(@recipe_dir) do
      ey "recipes upload", :debug => true
    end

    @out.should =~ /recipes uploaded successfully/i
  end

  it "complains when it can't infer the environment from the current application" do
    api_scenario "one app, one environment, not linked", "user@host.tld:path/to/repo.git"

    Dir.chdir(@recipe_dir) do
      ey "recipes upload", :debug => true, :expect_failure => true
    end

    @err.should =~ /single environment/i
  end
end
