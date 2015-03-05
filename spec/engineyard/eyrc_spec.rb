require 'spec_helper'
require 'engineyard/eyrc'

describe EY::EYRC do
  before { clean_eyrc }

  describe ".load" do
    it "looks for .eyrc in $EYRC if set" do
      expect(EY::EYRC.load.path).to eq(Pathname.new(ENV['EYRC']))
    end

    it "looks for .eyrc in $HOME/.eyrc by default" do
      ENV.delete('EYRC')
      expect(EY::EYRC.load.path).to eq(Pathname.new("#{ENV['HOME']}/.eyrc"))
    end
  end

  describe ".new" do
    it "looks for eyrc in any passed file location" do
      expect(EY::EYRC.new('/tmp/neweyrc').path).to eq(Pathname.new('/tmp/neweyrc'))
    end
  end

  context "with a non-existing .eyrc file" do
    it "has nil api_token" do
      expect(File.exists?("/tmp/nonexistant")).to be_falsey
      eyrc = EY::EYRC.new('/tmp/nonexistant')
      expect(eyrc.exist?).to be_falsey
      expect(eyrc.api_token).to be_nil
    end
  end

  context "saving api token" do
    before do
      EY::EYRC.load.api_token = 'abcd'
    end

    it "exists" do
      expect(EY::EYRC.load.exist?).to be_truthy
    end

    it "recalls the api_token" do
      expect(EY::EYRC.load.api_token).to eq('abcd')
    end

    it "deletes the api_token" do
      EY::EYRC.load.delete_api_token
      expect(EY::EYRC.load.api_token).to be_nil
    end

    it "writes the api_token to api_token: .eyrc" do
      expect(read_yaml(ENV['EYRC'])).to eq({"api_token" => "abcd"})
    end
  end

  context "file contains other random info" do
    before do
      # contains legacy endpoint behavior, no longer supported, but we won't be destructive.
      write_yaml({"api_token" => "1234", "http://localhost/" => {"api_token" => "5678"}}, ENV['EYRC'])
      EY::EYRC.load.api_token = 'abcd' # overwrites 1234
    end

    it "recalls the api_token" do
      expect(EY::EYRC.load.api_token).to eq('abcd')
    end

    it "deletes the api token safely on logout" do
      EY::EYRC.load.delete_api_token
      expect(read_yaml(ENV['EYRC'])).to eq({"http://localhost/" => {"api_token" => "5678"}})
    end

    it "maintains other random info in the file" do
      expect(read_yaml(ENV['EYRC'])).to eq({"api_token" => "abcd", "http://localhost/" => {"api_token" => "5678"}})
    end
  end
end
