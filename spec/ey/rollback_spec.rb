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
    expect(@out).to match(/Rolling back.*#{scenario[:application]}.*#{scenario[:environment]}/)
    expect(@err).to eq('')
    expect(@ssh_commands.last).to match(/engineyard-serverside.*deploy rollback.*--app #{scenario[:application]}/)
  end

  include_examples "it takes an environment name and an app name and an account name"
  include_examples "it invokes engineyard-serverside"

  it "passes along the web server stack to engineyard-serverside" do
    login_scenario "one app, one environment"
    ey %w[rollback]
    expect(@ssh_commands.last).to match(/--stack nginx_mongrel/)
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
      ey %w[rollback --config some:stuff more:crap]
      expect(config_options).not_to be_nil
      expect(config_options['some']).to eq('stuff')
      expect(config_options['more']).to eq('crap')
      expect(config_options['input_ref']).not_to be_nil
      expect(config_options['deployed_by']).not_to be_nil
    end

    it "supports legacy --extra-deploy-hook-options" do
      ey %w[rollback --extra-deploy-hook-options some:stuff more:crap]
      expect(config_options).not_to be_nil
      expect(config_options['some']).to eq('stuff')
      expect(config_options['more']).to eq('crap')
    end

    context "when ey.yml is present" do
      before do
        write_yaml({"environments" => {"giblets" => {"beer" => "stout"}}}, 'ey.yml')
      end

      after { File.unlink("ey.yml") }

      it "overrides what's in ey.yml" do
        ey %w[rollback --config beer:esb]
        expect(config_options['beer']).to eq('esb')
      end
    end
  end

end
