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
    it "gets the api token from the cloud api" do
      FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/authenticate", :body => %|{"api_token": "asdf"}|)
      EY::Token.fetch("a@b.com", "foo").token.should == "asdf"
    end
    
    it "raises InvalidCredentials if the username and password are wrong" do
      FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/authenticate", :status => 401)
      
      lambda {
        EY::Token.fetch("a@b.com", "foo")
      }.should raise_error(EY::Token::InvalidCredentials)
    end
  end
end