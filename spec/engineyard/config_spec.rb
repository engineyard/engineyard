require 'spec_helper'
require 'uri'

describe EY::Config do
  describe "environments" do
    after { File.unlink('ey.yml') if File.exist?('ey.yml') }

    it "get loaded from the config file" do
      write_yaml({"environments" => {"production" => {"default" => true}}}, 'ey.yml')
      EY::Config.new.environments["production"]["default"].should be_true
    end

    it "are present when the config file has no environments key" do
      write_yaml({}, 'ey.yml')
      EY::Config.new.environments.should == {}
    end
  end

  describe "endpoint" do
    it "defaults to production EY Cloud" do
      EY::Config.new.endpoint.should == EY::Config.new.default_endpoint
    end

    it "loads the endpoint from $CLOUD_URL" do
      ENV['CLOUD_URL'] = "http://fake.local/"
      EY::Config.new.endpoint.should == 'http://fake.local/'
      ENV.delete('CLOUD_URL')
    end
  end

  describe "files" do
    it "looks for config/ey.yml" do
      FileUtils.mkdir_p('config')

      write_yaml({"environments" => {"staging"    => {"default" => true}}}, "ey.yml")
      write_yaml({"environments" => {"production" => {"default" => true}}}, "config/ey.yml")
      EY::Config.new.default_environment.should == "production"

      File.unlink('config/ey.yml') if File.exist?('config/ey.yml')
      File.unlink('ey.yml') if File.exist?('ey.yml')
    end

    it "looks for ey.yml" do
      write_yaml({"environments" => {"staging" => {"default" => true}}}, "ey.yml")

      EY::Config.new.default_environment.should == "staging"

      File.unlink('ey.yml') if File.exist?('ey.yml')
    end
  end
end
