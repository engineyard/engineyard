require 'spec_helper'
require 'yaml'

describe EY::Config do
  def write_config(data, file = "ey.yml")
    File.open(file, "w"){|f| YAML.dump(data, f) }
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

  describe "files" do
    it "looks for config/ey.yml" do
      write_config({"endpoint" => "something"}, "ey.yml")
      write_config({"endpoint" => "localhost"}, "config/ey.yml")
      EY::Config.new.endpoint.should == "localhost"
    end

    it "looks for ey.yml" do
      write_config({"endpoint" => "foo"}, "ey.yml")
      EY::Config.new.endpoint.should == "foo"
    end

    it "looks for the file given" do
      write_config({"endpoint" => "bar"}, "summat.yml")
      EY::Config.new("summat.yml").endpoint.should == "bar"
    end
  end

end