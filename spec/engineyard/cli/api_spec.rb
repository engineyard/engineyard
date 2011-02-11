require 'spec_helper'
require 'engineyard/cli'

describe EY::CLI::API do
  before(:all) do
    EY.ui = EY::CLI::UI.new
  end

  after(:all) do
    EY.ui = EY::UI.new
  end

  it "gets the api token from ~/.eyrc if possible" do
    File.open(File.expand_path("~/.eyrc"), "w") do |fp|
      YAML.dump({"api_token" => "asdf"}, fp)
    end

    EY::CLI::API.new.should == EY::CLI::API.new("asdf")
  end

  context "without saved api token" do
    before(:each) do
      FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :body => %|{"api_token": "asdf"}|, :content_type => 'application/json')

      @ask_calls = []
      require 'highline'
      require 'mocha'
      HighLine.any_instance.expects(:ask).with do |arg1, arg2, block|
        @ask_calls << arg1
        true
      end.returns("").twice

      @token = EY::CLI::API.new
    end

    it "asks you for your credentials" do
      @ask_calls.should == ["Email: ", "Password: "]
    end

    it "gets the api token" do
      @token.should == EY::CLI::API.new("asdf")
    end

    it "saves the api token to ~/.eyrc" do
      YAML.load_file(File.expand_path("~/.eyrc")).should == {"api_token" => "asdf"}
    end
  end

end