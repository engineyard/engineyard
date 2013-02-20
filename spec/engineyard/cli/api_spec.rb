require 'spec_helper'
require 'engineyard/cli'

describe EY::CLI::API do
  it "gets the api token from ~/.eyrc if possible" do
    write_eyrc({"api_token" => "asdf"})
    EY::CLI::API.new('http://fake.local', EY::CLI::UI.new).token.should == "asdf"
    clean_eyrc
  end

  it "uses the token specified token over the ENV token if passed" do
    ENV['ENGINEYARD_API_TOKEN'] = 'envtoken'
    EY::CLI::API.new('http://fake.local', EY::CLI::UI.new, 'specifiedtoken').token.should == 'specifiedtoken'
    ENV.delete('ENGINEYARD_API_TOKEN')
  end

  it "uses the token from $ENGINEYARD_API_TOKEN if set" do
    ENV['ENGINEYARD_API_TOKEN'] = 'envtoken'
    EY::CLI::API.new('http://fake.local', EY::CLI::UI.new).token.should == 'envtoken'
    ENV.delete('ENGINEYARD_API_TOKEN')
  end

  context "without saved api token" do
    before(:each) do
      clean_eyrc
      FakeWeb.register_uri(:post, "http://fake.local/api/v2/authenticate", :body => %|{"api_token": "asdf"}|, :content_type => 'application/json')

      EY::CLI::UI::Prompter.enable_mock!
      EY::CLI::UI::Prompter.add_answer "my@email.example.com"
      EY::CLI::UI::Prompter.add_answer "secret"

      capture_stdout do
        @api = EY::CLI::API.new('http://fake.local', EY::CLI::UI.new)
      end
    end

    it "asks you for your credentials" do
      EY::CLI::UI::Prompter.questions.should == ["Email: ","Password: "]
    end

    it "gets the api token" do
      @api.token.should == "asdf"
    end

    it "saves the api token to ~/.eyrc" do
      read_eyrc.should == {"api_token" => "asdf"}
    end
  end

end
