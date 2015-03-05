require 'spec_helper'
require 'uri'

describe EY::Config do
  describe "environments" do
    after { File.unlink('ey.yml') if File.exist?('ey.yml') }

    it "get loaded from the config file" do
      write_yaml({"environments" => {"production" => {"default" => true}}}, 'ey.yml')
      expect(EY::Config.new.environments["production"]["default"]).to be_truthy
    end

    it "are present when the config file has no environments key" do
      write_yaml({}, 'ey.yml')
      expect(EY::Config.new.environments).to eq({})
    end

    it "rases an error when yaml produces an unexpected result" do
      File.open('ey.yml', "w") {|f| f << "this isn't a hash" }
      expect { EY::Config.new }.to raise_error(RuntimeError, "ey.yml load error: Expected a Hash but a String was returned.")
    end

    it "doesnt crash on nil environment" do
      write_yaml({"environments" => {"production" => nil}}, 'ey.yml')
      expect(EY::Config.new.default_environment).to be_nil
    end
  end

  describe "endpoint" do
    it "defaults to production Engine Yard Cloud" do
      expect(EY::Config.new.endpoint).to eq(EY::Config.new.default_endpoint)
    end

    it "loads the endpoint from $CLOUD_URL" do
      ENV['CLOUD_URL'] = "http://fake.local/"
      expect(EY::Config.new.endpoint).to eq('http://fake.local/')
      ENV.delete('CLOUD_URL')
    end
  end

  describe "files" do
    it "looks for config/ey.yml" do
      FileUtils.mkdir_p('config')

      write_yaml({"environments" => {"staging"    => {"default" => true}}}, "ey.yml")
      write_yaml({"environments" => {"production" => {"default" => true}}}, "config/ey.yml")
      expect(EY::Config.new.default_environment).to eq("production")

      File.unlink('config/ey.yml') if File.exist?('config/ey.yml')
      File.unlink('ey.yml') if File.exist?('ey.yml')
    end

    it "looks for ey.yml" do
      write_yaml({"environments" => {"staging" => {"default" => true}}}, "ey.yml")

      expect(EY::Config.new.default_environment).to eq("staging")

      File.unlink('ey.yml') if File.exist?('ey.yml')
    end
  end
end
