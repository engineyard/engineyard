require 'spec_helper'

describe EY::APIClient::Resolver do
  def mock_api
    return @mock_api if @mock_api
    apps = mock('apps')
    apps.stub!(:named) do |name, *args|
      result = EY::APIClient::App.from_hash(:name => name)
      result.stub!(:environments => [])
      result
    end

    environments = mock('apps')
    environments.stub!(:named) do |name, *args|
      result = EY::APIClient::Environment.from_hash(:name => name)
      result.stub!(:apps => [])
      result
    end
    @mock_api = mock("api", :apps => apps, :environments => environments)
  end

  def resolver(options)
    EY::APIClient::Resolver.new(mock_api, options).tap do |r|
      r.instance_variable_set(:@app_environments, @app_environments)
    end
  end

  def new_app_env(options)
    @app_environments ||= []
    @app_environments << options
    options
  end


  before do
    @production = new_app_env(:environment_name => "app_production", :app_name => "app",           :account_name => "ey", :repository_uri => "git://github.com/repo/app.git")
    @staging    = new_app_env(:environment_name => "app_staging"   , :app_name => "app",           :account_name => "ey", :repository_uri => "git://github.com/repo/app.git")
    @big        = new_app_env(:environment_name => "bigapp_staging", :app_name => "bigapp",        :account_name => "ey", :repository_uri => "git://github.com/repo/bigapp.git")
    @ey_dup     = new_app_env(:environment_name => "app_duplicate" , :app_name => "app_duplicate", :account_name => "ey", :repository_uri => "git://github.com/repo/dup.git")
    @sumo       = new_app_env(:environment_name => "sumo_wrestler" , :app_name => "app_duplicate", :account_name => "ey", :repository_uri => "git://github.com/repo/dup.git")
    @me_dup     = new_app_env(:environment_name => "app_duplicate" , :app_name => "app_duplicate", :account_name => "me", :repository_uri => "git://github.com/repo/dup.git")
  end

  def repo(url)
    r = mock("repo", :has_remote? => false)
    r.stub!(:has_remote?).with(url).and_return(true)
    r
  end

  describe "#fetch" do
    it "raises argument error if the conditions are empty" do
      lambda { resolver({}).app_and_environment }.should raise_error(ArgumentError)
    end

    it "raises when there is no app match" do
      lambda { resolver(:environment_name => 'app_duplicate', :app_name => 'gibberish').app_and_environment }.should raise_error(EY::APIClient::InvalidAppError)
    end

    it "raises when there is no environment match" do
      lambda { resolver(:environment_name => 'gibberish', :app_name => 'app').app_and_environment }.should raise_error(EY::APIClient::NoEnvironmentError)
    end

    it "raises when there are no matches" do
      lambda { resolver(:environment_name => 'app_duplicate', :app_name => 'bigapp').app_and_environment }.should raise_error(EY::APIClient::NoMatchesError)
      lambda { resolver(:repo => repo("git://github.com/repo/app.git"), :environment_name => 'app_duplicate') .app_and_environment }.should raise_error(EY::APIClient::NoMatchesError)
    end

    it "raises when there is more than one match" do
      lambda { resolver(:app_name => "app").app_and_environment }.should raise_error(EY::APIClient::MultipleMatchesError)
      lambda { resolver(:account_name => "ey", :app_name => "app").app_and_environment }.should raise_error(EY::APIClient::MultipleMatchesError)
      lambda { resolver(:repo => repo("git://github.com/repo/dup.git")).app_and_environment }.should raise_error(EY::APIClient::MultipleMatchesError)
      lambda { resolver(:repo => repo("git://github.com/repo/app.git")).app_and_environment }.should raise_error(EY::APIClient::MultipleMatchesError)
    end

    it "does not include duplicate copies of apps across accounts when raising a more than one match error" do
      do_include = "--environment='sumo_wrestler' --app='app_duplicate' --account='ey'"
      do_not_include = "--environment='sumo_wrestler' --app='app_duplicate' --account='me'"
      lambda do
        resolver(:repo => repo("git://github.com/repo/dup.git")).app_and_environment
      end.should raise_error(EY::APIClient::MultipleMatchesError) {|e|
        e.message.should include(do_include)
        e.message.should_not include(do_not_include)
      }
    end

    it "returns one deployment whene there is only one match" do
      resolver(:account_name => "ey", :app_name => "big").app_and_environment.should resolve_to(@big)
      resolver(:environment_name => "production").app_and_environment.should resolve_to(@production)
      resolver(:repo => repo("git://github.com/repo/bigapp.git")).app_and_environment.should resolve_to(@big)
      resolver(:repo => repo("git://github.com/repo/app.git"), :environment_name => "staging").app_and_environment.should resolve_to(@staging)
    end

    it "doesn't care about case" do
      resolver(:account_name => "EY", :app_name => "big").app_and_environment.should resolve_to(@big)
      resolver(:account_name => "ey", :app_name => "BiG").app_and_environment.should resolve_to(@big)
    end

    it "returns the match when an app is specified even when there is a repo" do
      resolver(:account_name => "ey", :app_name => "bigapp", :repo => repo("git://github.com/repo/app.git")).app_and_environment.should resolve_to(@big)
    end

    it "returns the specific match even if there is a partial match" do
      resolver(:environment_name => 'app_staging', :app_name => 'app').app_and_environment.should resolve_to(@staging)
      resolver(:environment_name => "app_staging").app_and_environment.should resolve_to(@staging)
      resolver(:app_name => "app", :environment_name => "staging").app_and_environment.should resolve_to(@staging)
    end

    it "scopes searches under the correct account" do
      resolver(:account_name => "ey", :environment_name => "dup", :app_name => "dup").app_and_environment.should resolve_to(@ey_dup)
      resolver(:account_name => "me", :environment_name => "dup").app_and_environment.should resolve_to(@me_dup)
      resolver(:account_name => "me", :app_name => "dup").app_and_environment.should resolve_to(@me_dup)
    end
  end
end
