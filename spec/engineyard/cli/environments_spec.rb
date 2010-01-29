require 'spec_helper'
require 'cli'

describe EY::CLI::Environments do
  context "with a valid token" do
    before(:each) do
      File.open(File.expand_path("~/.eyrc"), "w") do |fp|
        fp.write(YAML.dump({"api_token" => "asdf"}))
      end
      FakeWeb.register_uri(:get, "https://cloud.engineyard.com/api/v2/environments",
                            :body => %|{"environments":
                                          [{"name": "foo",
                                            "instances_count": 2
                                          },
                                          {"name": "bar",
                                           "instances_count": 1
                                            }]}|)
    end

    it "prints the environments on the commmand line" do
      out = capture_stdout do
        EY::CLI::Environments.run
      end

      out.should include("foo, 2 instances")
      out.should include("bar, 1 instance")
    end
  end

end