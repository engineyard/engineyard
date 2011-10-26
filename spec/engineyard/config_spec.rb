require 'spec_helper'
require 'uri'

describe EY::Config do
  let(:path) { p = Pathname.new(Dir.tmpdir).join('ey-test'); p.join('config').mkpath; p }
  let(:custom_config) do
    {
      "environments" => {
        "production" => {"default" => true, "branch" => "deploy", "migration_command" => "rake"},
        "staging"    => {"branch" => "master", "migration_command" => "rake staging"},
      }
    }
  end

  before(:each) do
    ENV.delete('CLOUD_URL')
  end

  after(:each) do
    EY.reset
    path.rmtree
  end

  shared_examples_for "default config" do
    it "loads only with defaults" do
      EY.config.endpoint.should == URI.parse('https://cloud.engineyard.com/')
    end

    it "has no environments" do
      EY.config.environments.should be_empty
    end

    it "has no default environment" do
      EY.config.default_environment.should be_nil
    end

    it "are present when the config file has no environments key" do
      EY.config.environments.should == {}
    end

    it "has no default branch" do
      EY.config.default_branch.should be_nil
    end
  end

  shared_examples_for "custom config" do
    it "uses default endpoint" do
      EY.config.endpoint.should == URI.parse('https://cloud.engineyard.com/')
    end

    it "has the default environment" do
      EY.config.default_environment.should == 'production'
    end

    it "has the default environment's other options" do
      EY.config.environments['production']['migration_command'].should == 'rake'
    end

    it "has the other environment" do
      EY.config.environments['staging']['migration_command'].should == 'rake staging'
    end

    it "has the default branch for default environment" do
      EY.config.default_branch.should == 'deploy'
    end

    it "has the default branch for the other environment" do
      EY.config.default_branch('staging').should == 'master'
    end
  end

  context "outside of a repository" do
    before(:each) do
      ENV['GIT_DIR'] = path.to_s
      write_yaml(custom_config, path.join('ey.yml'))
      write_yaml(custom_config, path.join('config', 'ey.yml'))
    end

    after(:each) do
      ENV.delete('GIT_DIR')
    end

    it_behaves_like "default config"
  end

  context "inside of a git repository" do
    before(:each) do
      Dir.chdir(path.to_s) { `git init -q` }
      ENV['GIT_DIR'] = path.join('.git').to_s
      ENV['GIT_WORK_TREE'] = path.to_s
    end

    after(:each) do
      ENV.delete('GIT_DIR')
      ENV.delete('GIT_WORK_TREE')
    end

    it_behaves_like "default config"

    context "with config/ey.yml committed to the repository" do
      before(:each) do
        write_yaml(custom_config, path.join('config','ey.yml'))
        `git add config/ey.yml && git commit -m 'add ey.yml'`
      end

      it_behaves_like "custom config"
    end

    context "with ey.yml committed to the repository" do
      before(:each) do
        write_yaml(custom_config, path.join('ey.yml'))
        `git add ey.yml && git commit -m 'add ey.yml'`
      end

      it_behaves_like "custom config"
    end

    context "with both config/ey.yml and ey.yml committed to the repository" do
      before(:each) do
        write_yaml(custom_config, path.join('config', 'ey.yml'))
        write_yaml({"environments" => {"staging" => {"default" => true}}}, path.join('ey.yml'))
        `git add ey.yml config/ey.yml && git commit -m 'add ey.yml'`
      end

      it_behaves_like "custom config"

      it "prefers config/ey.yml over ey.yml" do
        EY.config.default_environment.should == 'production'
      end
    end

    context "with custom endpoint" do
      it "loads the endpoint from $CLOUD_URL" do
        ENV['CLOUD_URL'] = "http://fake.local/"
        EY.config.endpoint.should == URI.parse('http://fake.local')
        ENV.delete('CLOUD_URL')
      end
    end

    context "with invalid endpoint" do
      before(:each) do
        ENV['CLOUD_URL'] = 'not/absolute'
      end

      after(:each) do
        ENV.delete('CLOUD_URL')
      end

      it "raises on an invalid endpoint" do
        lambda { EY.config.endpoint }.should raise_error(EY::Config::ConfigurationError)
      end
    end
  end
end
