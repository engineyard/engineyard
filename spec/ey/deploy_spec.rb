require 'spec_helper'

describe "ey deploy without an eyrc file" do
  given "integration"

  it "prompts for authentication before continuing" do
    api_scenario "one app, one environment"

    ey(%w[deploy --no-migrate], :hide_err => true) do |input|
      input.puts(scenario_email)
      input.puts(scenario_password)
    end

    expect(@out).to include("We need to fetch your API token; please log in.")
    expect(@out).to include("Email:")
    expect(@out).to include("Password:")
    expect(@ssh_commands).not_to be_empty

    expect(read_eyrc).to eq({"api_token" => scenario_api_token})
  end

  it "uses the token on the command line" do
    api_scenario "one app, one environment"
    ey(%w[deploy --no-migrate --api-token] + [scenario_api_token])
    expect(@ssh_commands).not_to be_empty
  end
end


describe "ey deploy" do
  given "integration"

  def command_to_run(opts)
    cmd = ["deploy"]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--app"         << opts[:app]         if opts[:app]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd << "--ref"         << opts[:ref]         if opts[:ref]
    cmd << "--migrate"                           if opts[:migrate]
    cmd                    << opts[:migrate]     if opts[:migrate].respond_to?(:to_str)
    cmd << "--no-migrate"                        if opts[:migrate] == nil
    cmd << "--verbose"                           if opts[:verbose]
    cmd
  end

  def verify_ran(scenario)
    expect(@out).to match(/Beginning deploy.../)
    expect(@out).to match(/Application:\s+#{scenario[:application]}/)
    expect(@out).to match(/Environment:\s+#{scenario[:environment]}/)
    expect(@out).to match(/deployment recorded/i)
    expect(@ssh_commands).to have_command_like(/engineyard-serverside.*deploy.*--app #{scenario[:application]}/)
  end

  # common behavior
  include_examples "it takes an environment name and an app name and an account name"
  include_examples "it invokes engineyard-serverside"
end

describe "ey deploy" do
  given "integration"

  context "without ssh keys (with ssh enabled)" do
    before do
      ENV.delete('NO_SSH')
      allow(Net::SSH).to receive(:start).and_raise(Net::SSH::AuthenticationFailed.new("no key"))
    end

    after do
      ENV['NO_SSH'] = 'true'
    end

    it "tells you that you need to add an appropriate ssh key (even with --quiet)" do
      login_scenario "one app, one environment"
      fast_failing_ey %w[deploy --no-migrate --quiet]
      expect(@err).to include("Authentication Failed")
    end
  end

  context "with invalid input" do
    it "complains when there is no app" do
      login_scenario "empty"
      fast_failing_ey ["deploy"]
      expect(@err).to include(%|No application found|)
    end

    it "complains when the specified environment does not contain the app" do
      login_scenario "one app, one environment, not linked"
      fast_failing_ey %w[deploy -e giblets -r master]
      expect(@err).to match(/Application "rails232app" and environment "giblets" are not associated./)
    end

    it "complains when environment is not specified and app is in >1 environment" do
      login_scenario "one app, many environments"
      fast_failing_ey %w[deploy --ref master --no-migrate]
      expect(@err).to match(/Multiple application environments possible/i)
    end

    it "complains when the app master is in a non-running state" do
      login_scenario "one app, one environment, app master red"
      fast_failing_ey %w[deploy --environment giblets --ref master --no-migrate]
      expect(@err).not_to match(/No running instances/i)
      expect(@err).to match(/running.*\(green\)/)
    end
  end

  context "migration command" do
    before(:each) do
      login_scenario "one app, one environment"
    end

    context "no ey.yml" do
      def clean_ey_yml
        File.unlink 'ey.yml' if File.exist?('ey.yml')
        FileUtils.rm_r 'config' if FileTest.exist?('config')
      end

      before { clean_ey_yml }
      after  { clean_ey_yml }

      it "tells you to run ey init" do
        fast_failing_ey %w[deploy]
        expect(@err).to match(/ey init/)
        expect(@ssh_commands).to be_empty
      end

      it "tells you to run ey init" do
        fast_failing_ey %w[deploy --migrate]
        expect(@err).to match(/ey init/)
        expect(@ssh_commands).to be_empty
      end
    end

    it "can be disabled with --no-migrate" do
      fast_ey %w[deploy --no-migrate]
      expect(@ssh_commands.last).to match(/engineyard-serverside.*deploy/)
      expect(@ssh_commands.last).not_to match(/--migrate/)
    end

    it "runs the migrate command when one is given" do
      fast_ey ['deploy', '--migrate', 'thor fancy:migrate']
      expect(@ssh_commands.last).to match(/--migrate 'thor fancy:migrate'/)
    end

    context "ey.yml migrate only" do
      before { write_yaml({"defaults" => {"migrate" => true}}, 'ey.yml') }
      after  { File.unlink 'ey.yml' }

      it "tells you to run ey init" do
        fast_failing_ey %w[deploy]
        expect(@err).to match(/ey init/)
      end
    end

    context "ey.yml migration_command only" do
      before { write_yaml({"defaults" => {"migration_command" => "thor fancy:migrate"}}, 'ey.yml') }
      after  { File.unlink 'ey.yml' }

      it "tells you to run ey init" do
        fast_failing_ey %w[deploy]
        expect(@err).to match(/ey init/)
      end
    end

    context "ey.yml with environment specific options overriding the defaults" do
      before do
        write_yaml({
          "defaults" => { "migrate" => true, "migration_command" => "rake plain:migrate"},
          "environments" => {"giblets" => { "migration_command" => 'thor fancy:migrate' }}
        }, 'ey.yml')
      end
      after  { File.unlink 'ey.yml' }

      it "migrates with the custom command" do
        fast_ey %w[deploy]
        expect(@ssh_commands.last).to match(/--migrate 'thor fancy:migrate'/)
      end
    end

    context "disabled in ey.yml" do
      before { write_yaml({"defaults" => {"migrate" => false}}, 'ey.yml') }
      after  { File.unlink 'ey.yml' }

      it "does not migrate by default" do
        fast_ey %w[deploy]
        expect(@ssh_commands.last).to match(/engineyard-serverside.*deploy/)
        expect(@ssh_commands.last).not_to match(/--migrate/)
      end

      it "can be turned back on with --migrate" do
        fast_ey ["deploy", "--migrate", "rake fancy:migrate"]
        expect(@ssh_commands.last).to match(/--migrate 'rake fancy:migrate'/)
      end

      it "tells you to initialize ey.yml when --migrate is specified with no value" do
        fast_failing_ey %w[deploy --migrate]
        expect(@err).to match(/ey init/)
      end
    end

    context "customized and disabled in ey.yml" do
      before { write_yaml({"defaults" => { "migrate" => false, "migration_command" => "thor fancy:migrate" }}, 'ey.yml') }
      after  { File.unlink 'ey.yml' }

      it "does not migrate by default" do
        fast_ey %w[deploy]
        expect(@ssh_commands.last).not_to match(/--migrate/)
      end

      it "migrates with the custom command when --migrate is specified with no value" do
        fast_ey %w[deploy --migrate]
        expect(@ssh_commands.last).to match(/--migrate 'thor fancy:migrate'/)
      end
    end
  end

  context "the --framework-env option" do
    before(:each) do
      login_scenario "one app, one environment"
    end

    it "passes the framework environment" do
      fast_ey %w[deploy --no-migrate]
      expect(@ssh_commands.last).to match(/--framework-env production/)
    end
  end

  context "choosing something to deploy" do
    use_git_repo('deploy test')

    before(:all) do
      login_scenario "one app, one environment"
    end

    context "without a configured default branch" do
      it "defaults to the checked-out local branch" do
        fast_ey %w[deploy --no-migrate]
        expect(@ssh_commands.last).to match(/--ref resolved-current-branch/)
      end

      it "deploys another branch if given" do
        fast_ey %w[deploy --ref master --no-migrate]
        expect(@ssh_commands.last).to match(/--ref resolved-master/)
      end

      it "deploys a tag if given" do
        fast_ey %w[deploy --ref v1 --no-migrate]
        expect(@ssh_commands.last).to match(/--ref resolved-v1/)
      end

      it "allows using --branch to specify a branch" do
        fast_ey %w[deploy --branch master --no-migrate]
        expect(@ssh_commands.last).to match(/--ref resolved-master/)
      end

      it "allows using --tag to specify the tag" do
        fast_ey %w[deploy --tag v1 --no-migrate]
        expect(@ssh_commands.last).to match(/--ref resolved-v1/)
      end
    end

    context "with a configured default branch" do
      before(:each) do
        write_yaml({"environments" => {"giblets" => {"branch" => "master", "migrate" => false}}}, 'ey.yml')
      end

      after(:each) do
        File.unlink "ey.yml"
      end

      it "deploys the default branch by default" do
        fast_ey %w[deploy]
        expect(@ssh_commands.last).to match(/--ref resolved-master/)
      end

      it "complains about a non-default branch without --ignore-default-branch" do
        fast_failing_ey %w[deploy -r current-branch]
        expect(@err).to match(/default branch is set to "master"/)
      end

      it "deploys a non-default branch with --ignore-default-branch" do
        fast_ey %w[deploy -r current-branch --ignore-default-branch]
        expect(@ssh_commands.last).to match(/--ref resolved-current-branch/)
      end

      it "deploys a non-default branch with --R ref" do
        fast_ey %w[deploy -R current-branch]
        expect(@ssh_commands.last).to match(/--ref resolved-current-branch/)
      end
    end
  end

  context "when there is extra configuration" do
    before(:each) do
      write_yaml({"environments" => {"giblets" => {"migrate" => true, "migration_command" => "rake", "bert" => "ernie"}}}, 'ey.yml')
    end

    after(:each) do
      File.unlink("ey.yml")
    end

    it "no longer gets passed along to engineyard-serverside (since serverside will read it on its own)" do
      fast_ey %w[deploy --no-migrate]
      expect(@ssh_commands.last).not_to match(/"bert":"ernie"/)
    end
  end

  context "specifying an environment" do
    before(:all) do
      login_scenario "one app, many similarly-named environments"
    end

    it "lets you choose by complete name even if the complete name is ambiguous" do
      fast_ey %w[deploy --environment railsapp_staging --no-migrate]
      expect(@out).to match(/Beginning deploy.../)
      expect(@out).to match(/Ref:\s+master/)
      expect(@out).to match(/Environment:\s+railsapp_staging/)
    end
  end

  context "--config (--extra-deploy-hook-options)" do
    before(:all) do
      login_scenario "one app, one environment"
    end

    def config_options
      if @ssh_commands.last =~ /--config (.*?)(?: -|$)/
        # the echo strips off the layer of shell escaping, leaving us
        # with pristine JSON
        MultiJson.load `echo #{$1}`
      end
    end

    it "passes --config to engineyard-serverside" do
      ey %w[deploy --config some:stuff more:crap --no-migrate]
      expect(config_options).not_to be_nil
      expect(config_options['some']).to eq('stuff')
      expect(config_options['more']).to eq('crap')
    end

    it "supports legacy --extra-deploy-hook-options" do
      ey %w[deploy --extra-deploy-hook-options some:stuff more:crap --no-migrate]
      expect(config_options).not_to be_nil
      expect(config_options['some']).to eq('stuff')
      expect(config_options['more']).to eq('crap')
    end

    context "when ey.yml is present" do
      before do
        write_yaml({"environments" => {"giblets" => {"beer" => "stout", "migrate" => true, "migration_command" => "rake"}}}, 'ey.yml')
      end

      after { File.unlink("ey.yml") }

      it "overrides what's in ey.yml" do
        fast_ey %w[deploy --config beer:esb]
        expect(config_options['beer']).to eq('esb')
      end
    end
  end

  context "specifying the application" do
    before(:all) do
      login_scenario "one app, one environment"
    end

    before(:each) do
      @_deploy_spec_start_dir = Dir.getwd
      Dir.chdir(File.expand_path("~"))
    end

    after(:each) do
      Dir.chdir(@_deploy_spec_start_dir)
    end

    it "allows you to specify an app when not in a directory" do
      fast_ey %w[deploy --app rails232app --ref master --migrate]
      expect(@ssh_commands.last).to match(/--app rails232app/)
      expect(@ssh_commands.last).to match(/--ref resolved-master/)
      expect(@ssh_commands.last).to match(/--migrate 'rake db:migrate --trace'/)
    end

    it "requires that you specify a ref when specifying the application" do
      Dir.chdir(File.expand_path("~")) do
        fast_failing_ey %w[deploy --app rails232app --no-migrate]
        expect(@err).to match(/you must also specify the --ref/)
      end
    end

    it "requires that you specify a migrate option when specifying the application" do
      Dir.chdir(File.expand_path("~")) do
        fast_failing_ey %w[deploy --app rails232app --ref master]
        expect(@err).to match(/you must also specify .* --migrate or --no-migrate/)
      end
    end
  end

  context "setting a specific serverside version" do
    use_git_repo("deploy test")

    before(:all) do
      login_scenario "one app, one environment"
    end

    it "should send the correct serverside version when specified" do
      fast_ey %w[deploy --no-migrate --serverside-version 1.6.4]
      deploy_command = @ssh_commands.find {|c| c =~ /engineyard-serverside.*deploy/ }
      expect(deploy_command).to match(/engineyard-serverside _1.6.4_ deploy/)
    end

    it "should send the default serverside version when unspecified" do
      fast_ey %w[deploy --no-migrate]
      deploy_command = @ssh_commands.find {|c| c =~ /engineyard-serverside.*deploy/ }
      expect(deploy_command).to match(/engineyard-serverside _#{EY::ENGINEYARD_SERVERSIDE_VERSION}_ deploy/)
    end
  end

  context "sending necessary information" do
    use_git_repo("deploy test")

    before(:all) do
      login_scenario "one app, one environment"
      fast_ey %w[deploy --no-migrate]
      @deploy_command = @ssh_commands.find {|c| c =~ /engineyard-serverside.*deploy/ }
    end

    it "passes along the repository URL to engineyard-serverside" do
      expect(@deploy_command).to match(/--git user@git.host:path\/to\/repo.git/)
    end

    it "passes along the web server stack to engineyard-serverside" do
      expect(@deploy_command).to match(/--stack nginx_mongrel/)
    end
  end

end
