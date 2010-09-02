require 'spec_helper'

describe EY::Resolver do
  def api
    return @api if @api
    apps = Object.new
    def apps.named(name)
      result = EY::Model::App.from_hash(:name => name)
      result.stub!(:environments => [])
      result
    end
    environments = Object.new
    def environments.named(name)
      result = EY::Model::Environment.from_hash(:name => name)
      result.stub!(:apps => [])
      result
    end
    @api = mock("api", :apps => apps, :environments => environments)
  end

  def resolver
    @resolver ||= EY::Resolver.new(api).tap do |r|
      r.instance_variable_set("@app_deployments", [])
    end
  end

  def new_app_deployment(options)
    resolver.instance_variable_get("@app_deployments") << options
    options
  end

  let(:production) { new_app_deployment(:environment_name => "app_production", :app_name => "app",           :account => "ey", :repository_uri => "git://github.com/repo/app.git") }
  let(:staging)    { new_app_deployment(:environment_name => "app_staging"   , :app_name => "app",           :account => "ey", :repository_uri => "git://github.com/repo/app.git") }
  let(:big)        { new_app_deployment(:environment_name => "bigapp_staging", :app_name => "bigapp",        :account => "ey", :repository_uri => "git://github.com/repo/bigapp.git") }
  let(:ey_dup)     { new_app_deployment(:environment_name => "app_duplicate" , :app_name => "app_duplicate", :account => "ey", :repository_uri => "git://github.com/repo/dup.git") }
  let(:me_dup)     { new_app_deployment(:environment_name => "app_duplicate" , :app_name => "app_duplicate", :account => "me", :repository_uri => "git://github.com/repo/dup.git") }

  before do
    production
    staging
    big
    ey_dup
    me_dup
  end

  def repo(url)
    mock("repo", :urls => [url])
  end

  def resolve_to(expected)
    simple_matcher "resolve to" do |(app,environment), _|
      app.name.should == expected[:app_name]
      environment.name.should == expected[:environment_name]
    end
  end

  describe "#fetch" do
    it "raises argument error if the conditions are empty" do
      lambda { resolver.app_and_environment({}) }.should raise_error(ArgumentError)
    end

    it "raises when there is no app match" do
      lambda { resolver.app_and_environment(:environment_name => 'app_duplicate', :app_name => 'smallapp') }.should raise_error(EY::InvalidAppError)
    end

    it "raises when the git repo does not match any apps" do
      lambda { resolver.app_and_environment(:environment_name => 'app_duplicate', :repo => repo("git://github.com/no-such/app.git")) }.should raise_error(EY::NoAppError)
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
      lambda { resolver.app_and_environment(:account => "ey", :app_name => "app") }.should raise_error(EY::MultipleMatchesError)
      lambda { resolver.app_and_environment(:repo => repo("git://github.com/repo/dup.git")) }.should raise_error(EY::MultipleMatchesError)
      lambda { resolver.app_and_environment(:repo => repo("git://github.com/repo/app.git")) }.should raise_error(EY::MultipleMatchesError)
    end

    it "returns one deployment whene there is only one match" do
      resolver.app_and_environment(:account => "ey", :app_name => "big").should resolve_to(big)
      resolver.app_and_environment(:environment_name => "production").should resolve_to(production)
      resolver.app_and_environment(:repo => repo("git://github.com/repo/bigapp.git")).should resolve_to(big)
      resolver.app_and_environment(:repo => repo("git://github.com/repo/app.git"), :environment_name => "staging").should resolve_to(staging)
    end

    it "returns the match when an app is specified even when there is a repo" do
      resolver.app_and_environment(:account => "ey", :app_name => "bigapp", :repo => repo("git://github.com/repo/app.git")).should resolve_to(big)
    end

    it "returns the specific match even if there is a partial match" do
      resolver.app_and_environment(:environment_name => 'app_staging', :app_name => 'app').should resolve_to(staging)
      resolver.app_and_environment(:environment_name => "app_staging").should resolve_to(staging)
      resolver.app_and_environment(:app_name => "app", :environment_name => "staging").should resolve_to(staging)
    end

    it "scopes searches under the correct account" do
      resolver.app_and_environment(:account => "ey", :environment_name => "dup").should resolve_to(ey_dup)
      resolver.app_and_environment(:account => "ey", :app_name => "dup").should resolve_to(ey_dup)
      resolver.app_and_environment(:account => "me", :environment_name => "dup").should resolve_to(me_dup)
      resolver.app_and_environment(:account => "me", :app_name => "dup").should resolve_to(me_dup)
    end
  end
end
