require 'spec_helper'
require 'tempfile'

describe EY::DeployConfig::Migrate do
  before do
    @tempfile = Tempfile.new('ey.yml')
    @parent = EY::Config.new(@tempfile.path)
    @ui = EY::CLI::UI.new
    EY::CLI::UI::Prompter.enable_mock!
    @repo = mock('repo')
  end

  after do
    @tempfile.unlink
  end

  def env_config(opts=nil)
    @env_config ||= EY::Config::EnvironmentConfig.new(opts, 'envname', @parent)
  end

  def deploy_config(cli_options)
    EY::DeployConfig.new(cli_options, env_config, @repo, @ui)
  end

  context "inside a repository" do
    context "no migrate options set (interactive)" do
      it "prompts migrate and command and adds to defaults section" do
        EY::CLI::UI::Prompter.add_answer "" # default
        EY::CLI::UI::Prompter.add_answer ""
        @parent.should_receive(:set_default_option).with('migrate', true)
        @parent.should_receive(:set_default_option).with('migration_command', 'rake db:migrate')
        dc = deploy_config({})
        out = capture_stdout do
          dc.migrate.should be_true
          dc.migrate_command.should == 'rake db:migrate'
        end
        out.should =~ /#{@tempfile.path}: migrate settings saved for envname/
        out.should =~ /You can override this default with --migrate or --no-migrate/
        out.should =~ /Please git commit #{@tempfile.path} with these new changes./
      end

      it "prompts migration_command if first answer is yes" do
        EY::CLI::UI::Prompter.add_answer "yes" # default
        EY::CLI::UI::Prompter.add_answer "ruby script/migrate"
        @parent.should_receive(:set_default_option).with('migrate', true)
        @parent.should_receive(:set_default_option).with('migration_command', 'ruby script/migrate')
        dc = deploy_config({})
        capture_stdout do
          dc.migrate.should be_true
          dc.migrate_command.should == 'ruby script/migrate'
        end
      end

      it "doesn't prompt migration_command if first answer is no" do
        EY::CLI::UI::Prompter.add_answer "no" # default
        @parent.should_receive(:set_default_option).with('migrate', false)
        dc = deploy_config({})
        capture_stdout do
          dc.migrate.should be_false
          dc.migrate_command.should be_nil
        end
      end
    end

    context "with the migrate cli option" do
      it "returns the default migration command when is true" do
        dc = deploy_config({'migrate' => true})
        dc.migrate.should be_true
        dc.migrate_command.should == 'rake db:migrate'
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
      it "return the default migration command when the option is true" do
        env_config('migrate' => true, 'migration_command' => 'bar migrate')
        dc = deploy_config({})
        dc.migrate.should be_true
        dc.migrate_command.should == 'bar migrate'
      end

      it "return the false when migrate is false" do
        env_config('migrate' => false, 'migration_command' => 'bar migrate')
        dc = deploy_config({})
        dc.migrate.should be_false
        dc.migrate_command.should be_nil
      end

      it "return the default migration command when the option is true" do
        env_config('migrate' => true)
        dc = deploy_config({})
        dc.migrate.should be_true
        dc.migrate_command.should == 'rake db:migrate'
      end

      it "return the ey.yml migration_command when command line option --migrate is passed" do
        env_config('migrate' => false, 'migration_command' => 'bar migrate')
        dc = deploy_config({'migrate' => true})
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
        before { env_config('branch' => 'default') }

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
          @repo.should_receive(:current_branch).and_return('current')
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
