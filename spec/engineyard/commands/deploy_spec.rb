require 'spec_helper'

describe "ey deploy" do
  before(:all) do
    ENV['EYRC'] = "/tmp/eyrc"
    ENV['CLOUD_URL'] = "http://localhost:4000"
    FakeFS.deactivate!
  end

  after(:all) do
    ENV['CLOUD_URL'] = nil
    FakeFS.activate!
  end

  describe "without an eyrc file" do
    before(:each) do
      FileUtils.rm_rf(ENV['EYRC'])
    end

    it "prompts for authentication" do
      ey "deploy" do |input|
        input.puts("test@test.test")
        input.puts("test")
      end
      @out.should include("We need to fetch your API token, please login")
      @out.should include("Email:")
      @out.should include("Password:")
    end
  end

  describe "with an eyrc file" do
    before(:each) do
      token = { ENV['CLOUD_URL'] => {
        "api_token" => "f81a1706ddaeb148cfb6235ddecfc1cf"} }
      File.open(ENV['EYRC'], "w"){|f| YAML.dump(token, f) }
    end

    it "complains when there is no app" do
      return pending "this should not hit a live app"
      ey "deploy", :hide_err => true
      @err.should include %|no application configured|
    end

    it "complains when there is no environment" do
      return pending
      api_scenario :no_environments
      ey "deploy"
      @out.should match(/no environment/i)
    end

    it "runs when environment is known" do
      return pending
      api_scenario :one_environment
      ey "deploy"
      @out.should match(/deploying/i)
    end

    it "complains when environment is ambiguous" do
      return pending
      api_scenario :two_environments
      ey "deploy"
      @out.should match(/was called incorrectly/i)
    end
  end
end