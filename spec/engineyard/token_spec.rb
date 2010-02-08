require 'spec_helper'

describe EY::Token do
  context "with a .eyrc" do
    before(:each) do
      File.open(File.expand_path("~/.eyrc"), "w") do |fp|
        fp.write(YAML.dump({"api_token" => "asdf"}))
      end
    end

    it "gets the api token from the file" do
      EY::Token.from_file.token.should == "asdf"
    end

    describe "autenticate method" do
      it "returns the api token" do
        EY::Token::authenticate.should == EY::Token.new("asdf")
      end
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

    describe "authenticate method" do
      it "asks for a username and password" do
        FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :body => %|{"api_token": "asdf"}|)

        stdin = StringIO.new
        stdin << "\n\n"
        stdin.rewind

        resp = capture_stdout do
          EY::Token.authenticate(stdin)
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
            EY::Token.authenticate(stdin)
          end
        end

        it "creates a .eyrc with the api token" do
          YAML.load_file(File.expand_path("~/.eyrc")).should == {"api_token" => "asdf"}
        end

        it "doesn't ask you for credentials again" do
          stdout, stderr = capture_stdio do
            EY::Token.authenticate
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
            lambda { EY::Token.authenticate(stdin) }.should raise_error(EY::Token::Exit)
          end

          resp.should include("please login")
          resp.should include("Email:")
          resp.should include("Password:")
          resp.should include("Bad username or password")
        end
      end

    end
  end
end