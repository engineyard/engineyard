require 'spec_helper'
require 'engineyard/cli'

describe EY::CLI::API do
  it "gets the api token from ~/.eyrc if possible" do
    write_eyrc({"api_token" => "asdf"})
    expect(EY::CLI::API.new('http://fake.local', EY::CLI::UI.new).token).to eq("asdf")
    clean_eyrc
  end

  it "uses the token specified token over the ENV token if passed" do
    ENV['ENGINEYARD_API_TOKEN'] = 'envtoken'
    expect(EY::CLI::API.new('http://fake.local', EY::CLI::UI.new, 'specifiedtoken').token).to eq('specifiedtoken')
    ENV.delete('ENGINEYARD_API_TOKEN')
  end

  it "uses the token from $ENGINEYARD_API_TOKEN if set" do
    ENV['ENGINEYARD_API_TOKEN'] = 'envtoken'
    expect(EY::CLI::API.new('http://fake.local', EY::CLI::UI.new).token).to eq('envtoken')
    ENV.delete('ENGINEYARD_API_TOKEN')
  end

  context "without saved api token" do
    before(:each) do
      clean_eyrc
      stub_request(:post, "http://fake.local/api/v2/authenticate").to_return(body: %|{"api_token": "asdf"}|, headers: { content_type: 'application/json' })
      EY::CLI::UI::Prompter.enable_mock!
      EY::CLI::UI::Prompter.add_answer "my@email.example.com"
      EY::CLI::UI::Prompter.add_answer "secret"

      capture_stdout do
        @api = EY::CLI::API.new('http://fake.local', EY::CLI::UI.new)
      end
    end

    it "asks you for your credentials" do
      expect(EY::CLI::UI::Prompter.questions).to eq(["Email: ","Password: "])
    end

    it "gets the api token" do
      expect(@api.token).to eq("asdf")
    end

    it "saves the api token to ~/.eyrc" do
      expect(read_eyrc).to eq({"api_token" => "asdf"})
    end
  end

end
