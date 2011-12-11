require 'spec_helper'

describe "ey rollback" do
  given "integration"

  def command_to_run(opts)
    cmd = ["rollback"]
    cmd << "-e" << opts[:environment] if opts[:environment]
    cmd << "-a" << opts[:app]         if opts[:app]
    cmd << "-c" << opts[:account]     if opts[:account]
    cmd << "--verbose"                if opts[:verbose]
    cmd
  end

  def verify_ran(scenario)
    @out.should match(/Rolling back.*#{scenario[:application]}.*#{scenario[:environment]}/)
    @err.should == ''
    @ssh_commands.last.should match(/engineyard-serverside.*deploy rollback.*--app #{scenario[:application]}/)
  end

  include_examples "it takes an environment name and an app name and an account name"
  include_examples "it invokes engineyard-serverside"

  it "passes along the web server stack to engineyard-serverside" do
    api_scenario "one app, one environment"
    ey %w[rollback]
    @ssh_commands.last.should =~ /--stack nginx_mongrel/
  end

  context "--extra-deploy-hook-options" do
    before(:all) do
      api_scenario "one app, one environment"
    end

    def extra_deploy_hook_options
      if @ssh_commands.last =~ /--config (.*?)(?: -|$)/
        # the echo strips off the layer of shell escaping, leaving us
        # with pristine JSON
        JSON.parse `echo #{$1}`
      end
    end

    it "passes the extra configuration to engineyard-serverside" do
      ey %w[rollback --extra-deploy-hook-options some:stuff more:crap]
      extra_deploy_hook_options.should_not be_nil
      extra_deploy_hook_options['some'].should == 'stuff'
      extra_deploy_hook_options['more'].should == 'crap'
    end

    context "when ey.yml is present" do
      before do
        write_yaml({"environments" => {"giblets" => {"beer" => "stout"}}}, 'ey.yml')
      end

      after { File.unlink("ey.yml") }

      it "overrides what's in ey.yml" do
        ey %w[rollback --extra-deploy-hook-options beer:esb]
        extra_deploy_hook_options['beer'].should == 'esb'
      end
    end
  end

end
