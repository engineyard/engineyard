require 'spec_helper'
require 'yaml'

describe EY::Config do
  def write_config(data)
    File.open("cloud.yml", "w"){|f| YAML.dump(data, f) }
  end

  describe "environments" do
    it "get loaded from the config file" do
      write_config("environments" => {"production" => {"default" => true}})
      EY::Config.new.environments["production"]["default"].should be_true
    end

    it "are present when the config file has no environments key" do
      write_config("endpoint" => "localhost")
      EY::Config.new.environments.should == {}
    end
  end

  describe "endpoint" do
    it "defaults to production EY Cloud" do
      EY::Config.new.endpoint.should == EY::Config.new.default_endpoint
    end

    it "gets loaded from the config file" do
      write_config("endpoint" => "localhost")
      EY::Config.new.endpoint.should == "localhost"
    end
  end

  it "provides default_endpoint?" do
    write_config("endpoint" => "localhost")
    EY::Config.new.default_endpoint?.should_not be_true
  end

end