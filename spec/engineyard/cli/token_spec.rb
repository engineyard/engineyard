require 'spec_helper'
require 'engineyard/cli'

describe EY::CLI::Token do
  before(:all) do
    EY.ui = EY::CLI::UI.new
  end

  it "gets the api token from ~/.eyrc if possible" do
    File.open(File.expand_path("~/.eyrc"), "w") do |fp|
      YAML.dump({"api_token" => "asdf"}, fp)
    end

    EY::CLI::Token.new.should == EY::CLI::Token.new("asdf")
  end

  context "without saved api token" do
    before(:each) do
      FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :body => %|{"api_token": "asdf"}|)

      capture_stdout("\n\n") do
        @token = EY::CLI::Token.new
      end
    end

    it "asks you for your credentials" do
      @out.should include("Email:")
      @out.should include("Password:")
    end

    it "gets the api token" do
      @token.should == EY::CLI::Token.new("asdf")
    end

    it "saves the api token to ~/.eyrc" do
      YAML.load_file(File.expand_path("~/.eyrc")).should == {"api_token" => "asdf"}
    end
  end

end