require 'spec_helper'

describe EY::APIClient do
  describe "endpoint" do
    it "defaults to production EY Cloud" do
      EY::APIClient.endpoint.should == URI.parse('https://cloud.engineyard.com')
    end

    it "loads saves a valid endpoint" do
      EY::APIClient.endpoint = "http://fake.local/"
      EY::APIClient.endpoint.should == URI.parse('http://fake.local')
      EY::APIClient.default_endpoint!
    end

    it "raises on an invalid endpoint" do
      lambda { EY::APIClient.endpoint = "non/absolute" }.should raise_error(EY::APIClient::BadEndpointError)
      EY::APIClient.default_endpoint!
    end
  end

  it "gets the api token from initialize" do
    EY::APIClient.new('asdf').token.should == "asdf"
  end

  describe ".authenticate" do
    before(:each) do
      FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :body => %|{"api_token": "asdf"}|, :content_type => 'application/json')
    end

    it "returns the token" do
      EY::APIClient.authenticate("a@b.com", "foo").should == "asdf"
    end
  end

  it "raises InvalidCredentials when the credentials are invalid" do
    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :status => 401, :content_type => 'application/json')

    lambda {
      EY::APIClient.authenticate("a@b.com", "foo")
    }.should raise_error(EY::APIClient::InvalidCredentials)
  end

  it "raises RequestFailed with a friendly error when cloud is under maintenance" do
    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :status => 502, :content_type => 'text/html')

    lambda {
      EY::APIClient.authenticate("a@b.com", "foo")
    }.should raise_error(EY::APIClient::RequestFailed, /API is temporarily unavailable/)
  end
end
