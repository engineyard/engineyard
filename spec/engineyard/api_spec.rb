require 'spec_helper'

describe EY::API do
  it "gets the api token from ~/.eyrc if possible" do
    File.open(File.expand_path("~/.eyrc"), "w") do |fp|
      YAML.dump({"api_token" => "asdf"}, fp)
    end

    EY::API.new.should == EY::API.new("asdf")
  end

  context "fetching the token from EY cloud" do
    before(:each) do
      FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :body => %|{"api_token": "asdf"}|)
      @token = EY::API.fetch_token("a@b.com", "foo")
    end

    it "returns an EY::API" do
      @token.should == "asdf"
    end

    it "puts the api token into .eyrc" do
      YAML.load_file(File.expand_path("~/.eyrc"))["api_token"].should == "asdf"
    end
  end

  it "raises InvalidCredentials when the credentials are invalid" do
    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :status => 401)

    lambda {
      EY::API.fetch_token("a@b.com", "foo")
    }.should raise_error(EY::Error)
  end

end