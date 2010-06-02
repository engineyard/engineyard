require 'spec_helper'

describe "ey recipes upload" do
  it_should_behave_like "an integration test"

  it "posts the recipes to the correct url" do
    api_scenario "one app, one environment"
    dir = Pathname.new("/tmp/#{$$}")
    dir.mkdir
    Dir.chdir(dir) do
      dir.join("cookbooks").mkdir
      File.open(dir.join("cookbooks/file"), "w"){|f| f << "boo" }
      `git init`
      `git add .`
      `git commit -m "OMG"`
      ey "recipes upload giblets", :debug => true
    end

    @out.should =~ /recipes uploaded successfully/i
  end

  it "errors correctly on bogus env name" do
    api_scenario "one app, one environment"
    ey "recipes upload bogusenv", :expect_failure => true

    @err.should =~ /can't be found/i
  end
end
