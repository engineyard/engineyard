require 'spec_helper'

describe EY::API do
  it "gets the api token from ~/.eyrc if possible" do
    write_config({"api_token" => "asdf"}, '~/.eyrc')
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
      load_config('~/.eyrc')["api_token"].should == "asdf"
    end
  end

  describe "saving the token" do
    context "without a custom endpoint" do
      it "saves the api token at the root of the data" do
        EY::API.save_token("asdf")
        load_config('~/.eyrc')["api_token"].should == "asdf"
      end
    end

    context "with a custom endpoint" do
      before do
        write_config({"endpoint" => "http://localhost/"}, 'ey.yml')
      end

      it "saves the api token nested under the endpoint url" do
        EY::API.save_token("asdf")
        load_config('~/.eyrc').should == {"http://localhost/" => {"api_token" => "asdf"}}
      end
    end
  end

  it "raises InvalidCredentials when the credentials are invalid" do
    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :status => 401)

    lambda {
      EY::API.fetch_token("a@b.com", "foo")
    }.should raise_error(EY::Error)
  end

end
