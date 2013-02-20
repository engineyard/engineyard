require 'spec_helper'
require 'engineyard/eyrc'

describe EY::EYRC do
  before { clean_eyrc }

  describe ".load" do
    it "looks for .eyrc in $EYRC if set" do
      EY::EYRC.load.path.should == Pathname.new(ENV['EYRC'])
    end

    it "looks for .eyrc in $HOME/.eyrc by default" do
      ENV.delete('EYRC')
      EY::EYRC.load.path.should == Pathname.new("#{ENV['HOME']}/.eyrc")
    end
  end

  describe ".new" do
    it "looks for eyrc in any passed file location" do
      EY::EYRC.new('/tmp/neweyrc').path.should == Pathname.new('/tmp/neweyrc')
    end
  end

  context "with a non-existing .eyrc file" do
    it "has nil api_token" do
      File.exists?("/tmp/nonexistant").should be_false
      eyrc = EY::EYRC.new('/tmp/nonexistant')
      eyrc.exist?.should be_false
      eyrc.api_token.should be_nil
    end
  end

  context "saving api token" do
    before do
      EY::EYRC.load.api_token = 'abcd'
    end

    it "exists" do
      EY::EYRC.load.exist?.should be_true
    end

    it "recalls the api_token" do
      EY::EYRC.load.api_token.should == 'abcd'
    end

    it "deletes the api_token" do
      EY::EYRC.load.delete_api_token
      EY::EYRC.load.api_token.should be_nil
    end

    it "writes the api_token to api_token: .eyrc" do
      read_yaml(ENV['EYRC']).should == {"api_token" => "abcd"}
    end
  end

  context "file contains other random info" do
    before do
      # contains legacy endpoint behavior, no longer supported, but we won't be destructive.
      write_yaml({"api_token" => "1234", "http://localhost/" => {"api_token" => "5678"}}, ENV['EYRC'])
      EY::EYRC.load.api_token = 'abcd' # overwrites 1234
    end

    it "recalls the api_token" do
      EY::EYRC.load.api_token.should == 'abcd'
    end

    it "deletes the api token safely on logout" do
      EY::EYRC.load.delete_api_token
      read_yaml(ENV['EYRC']).should == {"http://localhost/" => {"api_token" => "5678"}}
    end

    it "maintains other random info in the file" do
      read_yaml(ENV['EYRC']).should == {"api_token" => "abcd", "http://localhost/" => {"api_token" => "5678"}}
    end
  end
end
