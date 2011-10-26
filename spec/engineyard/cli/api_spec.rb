require 'spec_helper'
require 'engineyard/cli'

describe EY::CLI::API do
  before(:each) do
    EY.ui = EY::CLI::UI.new
  end

  after(:each) do
    EY.ui = EY::UI.new
  end

  it "gets the api token from ~/.eyrc if possible" do
    write_eyrc({"api_token" => "asdf"})
    EY::CLI::API.new.should == EY::CLI::API.new("asdf")
  end

  context "without saved api token" do
    before(:each) do
      FakeWeb.register_uri(:post, "http://fake.local/api/v2/authenticate", :body => %|{"api_token": "asdf"}|, :content_type => 'application/json')

      EY::CLI::UI::Prompter.enable_mock!
      EY::CLI::UI::Prompter.backend.next_answer "my@email.example.com"
      EY::CLI::UI::Prompter.backend.next_answer "secret"

      @api = EY::CLI::API.new(nil)
    end

    it "asks you for your credentials" do
      EY::CLI::UI::Prompter.backend.questions.should == ["Email: ","Password: "]
    end

    it "gets the api token" do
      @api.token.should == "asdf"
    end

    it "saves the api token to ~/.eyrc" do
      read_eyrc.should == {"api_token" => "asdf"}
    end
  end

end
