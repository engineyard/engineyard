require 'spec_helper'

describe EY::Token do
  context "with a .eyrc" do
    before(:each) do
      File.open(File.expand_path("~/.eyrc"), "w") do |fp|
        fp.write(YAML.dump({"api_token" => "asdf"}))
      end
    end

    it "gets the api token" do
      EY::Token.from_file.token.should == "asdf"
    end
  end

  context "without a .eyrc" do
    context "with valid credentials" do
      before(:each) do
        FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :body => %|{"api_token": "asdf"}|)
        @token = EY::Token.fetch("a@b.com", "foo")
      end
      
      it "gets the api token from the cloud api" do
        @token.token.should == "asdf"
      end
      
      it "puts the api token into .eyrc" do
        YAML.load_file(File.expand_path("~/.eyrc"))["api_token"].should == "asdf"
      end
    end

    context "with invalid credentials" do
      it "raises InvalidCredentials" do
        FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :status => 401)

        lambda {
          EY::Token.fetch("a@b.com", "foo")
          }.should raise_error(EY::Token::InvalidCredentials)
        end
      end
    end
  end