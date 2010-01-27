require 'spec_helper'
require 'cli'

describe EY::CLI do
  context "without a .eyrc" do
    it "asks for a username and password" do
      FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :body => %|{"api_token": "asdf"}|)
      
      stdin = StringIO.new
      stdin << "\n\n"
      stdin.rewind
      
      resp = capture_stdout do
        EY::CLI.authenticate(stdin)
      end
      
      resp.should include("please login")
      resp.should include("Email:")
      resp.should include("Password:")
    end
    
    context "with correct credentials" do
      before(:each) do
        FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :body => %|{"api_token": "asdf"}|)
        
        stdin = StringIO.new
        stdin << "foo\nbar\n"
        stdin.rewind
        
        capture_stdio do
          EY::CLI.authenticate(stdin)
        end
      end
      
      it "creates a .eyrc with the api token" do
        YAML.load_file(File.expand_path("~/.eyrc")).should == {"api_token" => "asdf"}
      end
      
      it "doesn't ask you for credentials again" do 
        stdout, stderr = capture_stdio do
          EY::CLI.authenticate
        end
        
        stdout.should_not include("please login")
      end
    end
    
    context "with invalid credentials" do
      before(:each) do
        FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :status => 401)
      end
      
      it "notifies you of the error" do
        stdin = StringIO.new
        stdin << "\n\n"
        stdin.rewind

        resp = capture_stdout do
          lambda { EY::CLI.authenticate(stdin) }.should raise_error(EY::CLI::Exit)
        end

        resp.should include("please login")
        resp.should include("Email:")
        resp.should include("Password:")
        resp.should include("Bad username or password")
      end
    end
  end
  
  context "with a .eyrc" do
    before(:each) do
      File.open(File.expand_path("~/.eyrc"), "w") do |fp|
        fp.write(YAML.dump({"api_token" => "asdf"}))
      end
    end
    
    it "returns the api token" do
      EY::CLI::authenticate.token.should == "asdf"
    end
  end
end