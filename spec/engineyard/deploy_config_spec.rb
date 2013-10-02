require 'spec_helper'
require 'tempfile'

describe EY::DeployConfig do
  let(:tempfile) { @tempfile = Tempfile.new('ey.yml') }
  let(:parent)   { EY::Config.new(tempfile.path) }
  let(:ui)       { EY::CLI::UI.new }
  let(:repo)     { double('repo') }
  let(:env)      { env_config(nil) }

  after { @tempfile.unlink if @tempfile }

  def env_config(opts, config = parent)
    EY::Config::EnvironmentConfig.new(opts, 'envname', config)
  end

  def deploy_config(cli_opts, ec = env)
    EY::DeployConfig.new(cli_opts, ec, repo, ui)
  end

  context "inside a repository" do
    context "with no ey.yml file" do
      let(:env) { env_config(nil, EY::Config.new('noexisto.yml')) }

      it "tells you to initialize a new repository with ey init" do
        dc = deploy_config({}, env)
        expect { dc.migrate }.to raise_error(EY::Error, /Please initialize this application with the following command:/)
      end
    end

    context "with the migrate cli option" do
      it "returns default command when true" do
        dc = deploy_config({'migrate' => true})
        dc.migrate.should be_true
        expect { dc.migrate_command }.to raise_error(EY::Error, /'migration_command' not found/)
      end

      it "returns false when nil" do
        dc = deploy_config({'migrate' => nil})
        dc.migrate.should be_false
        dc.migrate_command.should be_nil
      end

      it "return the custom migration command when is a string" do
        dc = deploy_config({'migrate' => 'foo migrate'})
        dc.migrate.should be_true
        dc.migrate_command.should == 'foo migrate'
      end
    end

    context "with the migrate option in the global configuration" do
      it "return the migration command when the option is true" do
        env = env_config('migrate' => true, 'migration_command' => 'bar migrate')
        dc = deploy_config({}, env)
        dc.migrate.should be_true
        dc.migrate_command.should == 'bar migrate'
      end

      it "return the false when migrate is false" do
        env = env_config('migrate' => false, 'migration_command' => 'bar migrate')
        dc = deploy_config({}, env)
        dc.migrate.should be_false
        dc.migrate_command.should be_nil
      end

      it "tells you to run ey init" do
        env = env_config('migrate' => true)
        dc = deploy_config({}, env)
        expect(dc.migrate).to be_true
        expect { dc.migrate_command }.to raise_error(EY::Error, /'migration_command' not found/)
      end

      it "return the ey.yml migration_command when command line option --migrate is passed" do
        env = env_config('migrate' => false, 'migration_command' => 'bar migrate')
        dc = deploy_config({'migrate' => true}, env)
        dc.migrate.should be_true
        dc.migrate_command.should == 'bar migrate'
      end
    end

    describe "ref" do
      it "returns the passed ref" do
        deploy_config({'ref' => 'master'}).ref.should == 'master'
      end

      it "returns the passed force_ref" do
        deploy_config({'force_ref' => 'force'}).ref.should == 'force'
      end

      it "returns the ref if force_ref is true" do
        deploy_config({'ref' => 'master', 'force_ref' => true}).ref.should == 'master'
      end

      it "overrides the ref if force_ref is set to a string" do
        deploy_config({'ref' => 'master', 'force_ref' => 'force'}).ref.should == 'force'
      end

      context "with a default branch" do
        let(:env) { env_config('branch' => 'default') }

        it "uses the configured default if ref is not passed" do
          out = capture_stdout do
            deploy_config({}).ref.should == 'default'
          end
          out.should =~ /Using default branch "default" from ey.yml/
        end

        it "raises if a default is set and --ref is passed on the cli (and they don't match)" do
          lambda { deploy_config({'ref' => 'master'}).ref }.should raise_error(EY::BranchMismatchError)
        end

        it "returns the default if a default is set and --ref is the same" do
          deploy_config({'ref' => 'default'}).ref.should == 'default'
        end

        it "returns the ref if force_ref is set" do
          out = capture_stdout do
            deploy_config({'ref' => 'master', 'force_ref' => true}).ref.should == 'master'
          end
          out.should =~ /Default ref overridden with "master"/
        end

        it "returns the ref if force_ref is a branch" do
          out = capture_stdout do
            deploy_config({'force_ref' => 'master'}).ref.should == 'master'
          end
          out.should =~ /Default ref overridden with "master"/
        end
      end

      context "no options, no default" do
        it "uses the repo's current branch" do
          repo.should_receive(:current_branch).and_return('current')
          out = capture_stdout do
            deploy_config({}).ref.should == 'current'
          end
          out.should =~ /Using current HEAD branch "current"/
        end
      end
    end
  end

  context "when outside of a repo" do
    describe "migrate" do
      it "returns the default migration command when migrate is true" do
        dc = deploy_config({'app' => 'app', 'migrate' => true})
        dc.migrate.should be_true
        dc.migrate_command.should == 'rake db:migrate'
      end

      it "returns false when nil" do
        dc = deploy_config({'app' => 'app', 'migrate' => nil})
        dc.migrate.should be_false
        dc.migrate_command.should be_nil
      end

      it "return the custom migration command when is a string" do
        dc = deploy_config({'app' => 'app', 'migrate' => 'foo migrate'})
        dc.migrate.should be_true
        dc.migrate_command.should == 'foo migrate'
      end

      it "raises if migrate is not passed" do
        lambda { deploy_config({'app' => 'app'}).migrate }.should raise_error(EY::RefAndMigrateRequiredOutsideRepo)
      end
    end

    describe "ref" do
      it "returns the passed ref" do
        dc = deploy_config({'app' => 'app', 'ref' => 'master'})
        dc.ref.should == 'master'
      end

      it "returns the passed force_ref" do
        dc = deploy_config({'app' => 'app', 'force_ref' => 'force'})
        dc.ref.should == 'force'
      end

      it "returns the ref if force_ref is true" do
        dc = deploy_config({'app' => 'app', 'ref' => 'master', 'force_ref' => true})
        dc.ref.should == 'master'
      end

      it "overrides the ref if force_ref is set to a string" do
        dc = deploy_config({'app' => 'app', 'ref' => 'master', 'force_ref' => 'force'})
        dc.ref.should == 'force'
      end

      it "raises if ref is not passed" do
        lambda { deploy_config({'app' => 'app'}).ref }.should raise_error(EY::RefAndMigrateRequiredOutsideRepo)
      end
    end
  end
end
