require 'spec_helper'

describe "ey init" do
  given "integration"

  let(:default_migration_command) { "rake db:migrate" }

  before do
    login_scenario "one app, one environment"
  end

  before { clean_ey_yml }
  after  { clean_ey_yml }

  context "with no ey.yml file" do
    it "writes the file" do
      fast_ey %w[init]

      expect(ey_yml).to exist
      expect_config('migrate').to eq(false)
    end
  end

  context "with existing ey.yml file" do
    let(:existing) {
      {
        "defaults" => {
          "migrate" => false,
          "migration_command" => "thor fancy:migrate",
          "precompile_assets" => false,
          "precompile_assets_task" => "assets:precompile",
        },
        "environments" => {
          "my_env" => {
            "default" => true,
            "migrate" => true,
            "migration_command" => default_migration_command,
          }
        }
      }
    }

    before do
      write_yaml(existing, 'ey.yml')
    end

    it "reinitializes the file" do
      fast_ey %w[init]

      expect_config('defaults','migration_command').to eq("thor fancy:migrate")
      expect_config('defaults','migrate').to eq(false)
      expect_config('defaults','precompile_assets').to eq(false)

      expect_config('environments','my_env','default').to eq(true)
      expect_config('environments','my_env','migrate').to eq(true)
      expect_config('environments','my_env','migration_command').to eq(default_migration_command)
    end

    it "makes a backup when overwriting an existing file" do
      fast_ey %w[init]
      data = read_yaml('ey.yml.backup')
      expect(data['defaults']['migration_command']).to eq('thor fancy:migrate')
    end
  end

  context "smart defaults" do
    describe "migrate" do
      let(:db) { Pathname.new('db') }
      let(:db_migrate) { db.join('migrate') }

      context "with db/migrate directory" do
        before { db_migrate.mkpath }
        after { db.rmtree }

        it "sets migrate to true and uses default migration command" do
          fast_ey %w[init]

          expect_config('migrate').to eq(true)
          expect_config('migration_command').to eq(default_migration_command)
        end
      end

      context "without db/migrate directory" do
        it "sets migrate to false and doesn't write migration_command" do
          expect(db_migrate).to_not exist

          fast_ey %w[init]

          expect_config('migrate').to eq(false)
          expect_config('migration_command').to be_nil
        end
      end
    end

    context "precompile_assets" do
      let(:app) { Pathname.new('app') }
      let(:assets) { app.join('assets') }

      context "with app/assets directory" do
        before { assets.mkpath }
        after { app.rmtree }

        it "sets precompile_assets to true and doesn't write precompile_assets_task" do
          fast_ey %w[init]

          expect_config('precompile_assets').to eq(true)
          expect_config('precompile_assets_task').to be_nil
        end
      end

      context "without app/assets directory" do
        it "sets precompile_assets to false and does not set an precompile_assets_task" do
          expect(assets).to_not exist

          fast_ey %w[init]

          expect_config('precompile_assets').to eq(false)
          expect_config('precompile_assets_task').to be_nil
        end
      end
    end
  end
end

__END__
  pending do
    it "uses the default command when --migrate is specified with no value" do
      fast_ey %w[init --migrate]

      expect_config('migrate').to eq(true)
      expect_config('migration_command').to eq(default_migration_command)
    end

    it "uses the specified command when --migrate COMMAND is given" do
      fast_ey ['init', '--migrate', 'my command']

      expect_config('migrate').to eq(true)
      expect_config('migration_command').to eq("my command")
    end

    it "turns off migration for --no-migrate" do
      fast_ey %w[init --no-migrate]

      expect_config('migrate').to eq(false)
    end

    it "turns string true into real true" do
      fast_ey %w[init --migrate true]

      expect_config('migrate').to eq(true)
      expect_config('migration_command').to eq(default_migration_command)
    end

    it "turns string false into real false" do
      fast_ey %w[init --migrate false]

      expect_config('migrate').to eq(false)
      expect_config('migration_command').to be_nil
    end
  end

  pending do
    it "uses the default command when --assets is specified with no value" do
      fast_ey %w[init --assets]

      expect_config('precompile_assets').to eq(true)
      expect_config('precompile_assets_task').to be_nil
    end

    it "uses the specified command when --assets COMMAND is given" do
      fast_ey %w[init --assets my:task]

      expect_config('precompile_assets').to eq(true)
      expect_config('precompile_assets_task').to eq("my:task")
    end

    it "turns off assets for --no-assets" do
      fast_ey %w[init --no-assets]

      expect_config('precompile_assets').to eq(false)
      expect_config('precompile_assets_task').to be_nil
    end

    it "turns string true into real true" do
      fast_ey %w[init --assets true]

      expect_config('precompile_assets').to eq(true)
      expect_config('precompile_assets_task').to be_nil
    end

    it "turns string false into real false" do
      fast_ey %w[init --assets false]

      expect_config('precompile_assets').to eq(false)
      expect_config('precompile_assets_task').to be_nil
    end
  end
end

  context "without ssh keys (with ssh enabled)" do
    before do
      ENV.delete('NO_SSH')
      Net::SSH.stub(:start).and_raise(Net::SSH::AuthenticationFailed.new("no key"))
    end

    after do
      ENV['NO_SSH'] = 'true'
    end

    it "tells you that you need to add an appropriate ssh key (even with --quiet)" do
      login_scenario "one app, one environment"
      fast_failing_ey %w[init]
      @err.should include("Authentication Failed")
    end
  end

  context "with invalid input" do
    it "complains when there is no app" do
      login_scenario "empty"
      fast_failing_ey ["init"]
      @err.should include(%|No application found|)
    end

    it "complains when the specified environment does not contain the app" do
      login_scenario "one app, one environment, not linked"
      fast_failing_ey %w[init -e giblets -r master]
      @err.should match(/Application "rails232app" and environment "giblets" are not associated./)
    end

    it "complains when environment is not specified and app is in >1 environment" do
      login_scenario "one app, many environments"
      fast_failing_ey %w[init --ref master --no-migrate]
      @err.should match(/Multiple application environments possible/i)
    end

  end

  context "migration command" do
    before(:each) do
      login_scenario "one app, one environment"
    end

    context "without migrate sepecified, interactively reads migration command" do

      before { clean_ey_yml }
      after  { clean_ey_yml }

      it "defaults to yes, and then rake db:migrate (and installs to config/ey.yml if config/ exists already)" do
        ey_yml = Pathname.new('config/ey.yml')
        File.exist?('ey.yml').should be_false
        ey_yml.dirname.mkpath
        ey_yml.should_not be_exist
        ey(%w[init]) do |input|
          input.puts('')
          input.puts('')
        end
        File.exist?('ey.yml').should be_false
        ey_yml.should be_exist
        env_conf = read_yaml(ey_yml.to_s)['defaults']
        env_conf['migrate'].should == true
        env_conf['migration_command'].should == 'rake db:migrate'
      end

      it "accepts new commands" do
        File.exist?('ey.yml').should be_false
        FileTest.exist?('config').should be_false
        ey(%w[init], :hide_err => true) do |input|
          input.puts("y")
          input.puts("ruby migrate")
        end
        File.exist?('ey.yml').should be_true
        env_conf = read_yaml('ey.yml')['defaults']
        env_conf['migrate'].should == true
        env_conf['migration_command'].should == 'ruby migrate'
      end

      it "doesn't ask for the command if you say no" do
        File.exist?('ey.yml').should be_false
        ey(%w[init], :hide_err => true) do |input|
          input.puts("no")
        end
        File.exist?('ey.yml').should be_true
        read_yaml('ey.yml')['defaults']['migrate'].should == false
      end
    end

    context "customized in ey.yml with defaults" do
      before { write_yaml({"defaults" => { "migration_command" => "thor fancy:migrate"}}, 'ey.yml') }
      after  { File.unlink 'ey.yml' }

      it "migrates with the custom command by default (and fixes ey.yml to reflect the previous default behavior)" do
        fast_ey %w[deploy]
        @ssh_commands.last.should =~ /--migrate 'thor fancy:migrate'/
        read_yaml('ey.yml')['defaults']['migrate'].should == true
      end
    end

    context "customized in ey.yml with environment specific options overriding the defaults" do
      before do
        write_yaml({
          "defaults" => { "migration_command" => "rake plain:migrate"},
          "environments" => {"giblets" => { "migration_command" => 'thor fancy:migrate' }}
        }, 'ey.yml')
      end
      after  { File.unlink 'ey.yml' }

      it "migrates with the custom command by default (and fixes ey.yml for the specific environment to reflect the previous default behavior)" do
        fast_ey %w[init]
        @ssh_commands.last.should =~ /--migrate 'thor fancy:migrate'/
        read_yaml('ey.yml')['defaults']['migrate'].should == true
      end
    end

    context "disabled in ey.yml" do
      before { write_yaml({"environments" => {"giblets" => {"migrate" => false}}}, 'ey.yml') }
      after  { File.unlink 'ey.yml' }

      it "does not migrate by default" do
        fast_ey %w[deploy]
        @ssh_commands.last.should =~ /engineyard-serverside.*init/
        @ssh_commands.last.should_not =~ /--migrate/
      end

      it "can be turned back on with --migrate" do
        fast_ey ["init", "--migrate", "rake fancy:migrate"]
        @ssh_commands.last.should =~ /--migrate 'rake fancy:migrate'/
      end

      it "migrates with the default when --migrate is specified with no value" do
        fast_ey %w[init --migrate]
        @ssh_commands.last.should match(/--migrate 'rake db:migrate'/)
      end
    end

    context "explicitly enabled in ey.yml (the default)" do
      before { write_yaml({"environments" => {"giblets" => {"migrate" => true}}}, 'ey.yml') }
      after  { File.unlink 'ey.yml' }

      it "migrates with the default (and writes the default to ey.yml)" do
        fast_ey %w[init]
        @ssh_commands.last.should match(/--migrate 'rake db:migrate'/)
        read_yaml('ey.yml')['defaults']['migration_command'].should == 'rake db:migrate'
      end
    end

    context "customized and disabled in ey.yml" do
      before { write_yaml({"environments" => {"giblets" => { "migrate" => false, "migration_command" => "thor fancy:migrate" }}}, 'ey.yml') }
      after  { File.unlink 'ey.yml' }

      it "does not migrate by default" do
        fast_ey %w[init]
        @ssh_commands.last.should_not match(/--migrate/)
      end

      it "migrates with the custom command when --migrate is specified with no value" do
        fast_ey %w[init --migrate]
        @ssh_commands.last.should match(/--migrate 'thor fancy:migrate'/)
      end
    end
  end

  context "specifying the application" do
    before(:all) do
      login_scenario "one app, one environment"
    end

    before(:each) do
      @_init_spec_start_dir = Dir.getwd
      Dir.chdir(File.expand_path("~"))
    end

    after(:each) do
      Dir.chdir(@_init_spec_start_dir)
    end

    it "allows you to specify an app when not in a directory" do
      fast_ey %w[init --app rails232app --ref master --migrate]
      @ssh_commands.last.should match(/--app rails232app/)
      @ssh_commands.last.should match(/--ref resolved-master/)
      @ssh_commands.last.should match(/--migrate 'rake db:migrate'/)
    end

    it "requires that you specify a ref when specifying the application" do
      Dir.chdir(File.expand_path("~")) do
        fast_failing_ey %w[init --app rails232app --no-migrate]
        @err.should match(/you must also specify the --ref/)
      end
    end

    it "requires that you specify a migrate option when specifying the application" do
      Dir.chdir(File.expand_path("~")) do
        fast_failing_ey %w[init --app rails232app --ref master]
        @err.should match(/you must also specify .* --migrate or --no-migrate/)
      end
    end
  end

end
