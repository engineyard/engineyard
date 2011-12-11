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

  def resolver
    @resolver ||= EY::APIClient::Resolver.new(mock_api).tap do |r|
      r.instance_variable_set(:@app_environments, [])
    end
  end

  def new_app_env(options)
    resolver.instance_variable_get(:@app_environments) << options
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
      lambda { resolver.app_and_environment({}) }.should raise_error(ArgumentError)
    end

    it "raises when there is no app match" do
      lambda { resolver.app_and_environment(:environment_name => 'app_duplicate', :app_name => 'smallapp') }.should raise_error(EY::InvalidAppError)
    end

    it "raises when there is no environment match" do
      lambda { resolver.app_and_environment(:environment_name => 'gibberish', :app_name => 'app') }.should raise_error(EY::NoEnvironmentError)
    end

    it "raises when there are no matches" do
      lambda { resolver.app_and_environment(:environment_name => 'app_duplicate', :app_name => 'bigapp') }.should raise_error(EY::NoMatchesError)
      lambda { resolver.app_and_environment(:repo => repo("git://github.com/repo/app.git"), :environment_name => 'app_duplicate') }.should raise_error(EY::NoMatchesError)
    end

    it "raises when there is more than one match" do
      lambda { resolver.app_and_environment(:app_name => "app") }.should raise_error(EY::MultipleMatchesError)
      lambda { resolver.app_and_environment(:account_name => "ey", :app_name => "app") }.should raise_error(EY::MultipleMatchesError)
      lambda { resolver.app_and_environment(:repo => repo("git://github.com/repo/dup.git")) }.should raise_error(EY::MultipleMatchesError)
      lambda { resolver.app_and_environment(:repo => repo("git://github.com/repo/app.git")) }.should raise_error(EY::MultipleMatchesError)
    end

    it "does not include duplicate copies of apps across accounts when raising a more than one match error" do
      do_include = "--environment='sumo_wrestler' --app='app_duplicate' --account='ey'"
      do_not_include = "--environment='sumo_wrestler' --app='app_duplicate' --account='me'"
      lambda do
        resolver.app_and_environment(:repo => repo("git://github.com/repo/dup.git"))
      end.should raise_error(EY::MultipleMatchesError) {|e|
        e.message.should include(do_include)
        e.message.should_not include(do_not_include)
      }
    end

    it "returns one deployment whene there is only one match" do
      resolver.app_and_environment(:account_name => "ey", :app_name => "big").should resolve_to(@big)
      resolver.app_and_environment(:environment_name => "production").should resolve_to(@production)
      resolver.app_and_environment(:repo => repo("git://github.com/repo/bigapp.git")).should resolve_to(@big)
      resolver.app_and_environment(:repo => repo("git://github.com/repo/app.git"), :environment_name => "staging").should resolve_to(@staging)
    end

    it "doesn't care about case" do
      resolver.app_and_environment(:account_name => "EY", :app_name => "big").should resolve_to(@big)
      resolver.app_and_environment(:account_name => "ey", :app_name => "BiG").should resolve_to(@big)
    end

    it "returns the match when an app is specified even when there is a repo" do
      resolver.app_and_environment(:account_name => "ey", :app_name => "bigapp", :repo => repo("git://github.com/repo/app.git")).should resolve_to(@big)
    end

    it "returns the specific match even if there is a partial match" do
      resolver.app_and_environment(:environment_name => 'app_staging', :app_name => 'app').should resolve_to(@staging)
      resolver.app_and_environment(:environment_name => "app_staging").should resolve_to(@staging)
      resolver.app_and_environment(:app_name => "app", :environment_name => "staging").should resolve_to(@staging)
    end

    it "scopes searches under the correct account" do
      resolver.app_and_environment(:account_name => "ey", :environment_name => "dup", :app_name => "dup").should resolve_to(@ey_dup)
      resolver.app_and_environment(:account_name => "me", :environment_name => "dup").should resolve_to(@me_dup)
      resolver.app_and_environment(:account_name => "me", :app_name => "dup").should resolve_to(@me_dup)
    end
  end
end
