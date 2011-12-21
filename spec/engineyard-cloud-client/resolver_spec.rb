require 'spec_helper'

describe EY::CloudClient::Resolver do
  def mock_api
    return @mock_api if @mock_api
    apps = mock('apps')
    apps.stub!(:named) { |name, account_name| get_app_named(name, account_name) }

    envs = mock('apps')
    envs.stub!(:named) { |name, account_name| get_env_named(name, account_name) }
    @mock_api = mock("api", :apps => apps, :environments => envs, :app_environments => [])
  end

  def get_app_named(name, account)
    mock_api.app_environments.map {|app_env| app_env.app}.detect do |app|
      app.name == name && app.account_name == account
    end
  end

  def get_env_named(name, account)
    mock_api.app_environments.map {|app_env| app_env.environment}.detect do |environment|
      environment.name == name && environment.account_name == account
    end
  end

  def resolver(options)
    EY::CloudClient::Resolver.new(mock_api, options)
  end

  def new_app_env(app, repository_uri, env, account)
    app_env = EY::CloudClient::AppEnvironment.from_hash(mock_api, {
      'app' => {
        'name' => app,
        'repository_uri' => repository_uri,
        'account' => {'name' => account},
      },
      'environment' => {
        'name' => env,
        'account' => {'name' => account},
      },
    })
    mock_api.app_environments << app_env
    app_env
  end


  before do
    @production = new_app_env("app",     "git://github.com/repo/app.git", "app_production", 'ey')
    @staging    = new_app_env("app",     "git://github.com/repo/app.git", "app_staging"   , 'ey')
    @big        = new_app_env("bigapp",  "git://github.com/repo/big.git", "bigapp_staging", 'ey')
    @ey_dup     = new_app_env("app_dup", "git://github.com/repo/dup.git", "app_dup" , 'ey')
    @sumo       = new_app_env("app_dup", "git://github.com/repo/dup.git", "sumo_wrestler" , 'ey')
    @me_dup     = new_app_env("app_dup", "git://github.com/repo/dup.git", "app_dup" , 'me')
  end

  def repo(url)
    r = mock("repo", :has_remote? => false)
    r.stub!(:has_remote?).with(url).and_return(true)
    r
  end

  describe "#fetch" do
    it "raises argument error if the conditions are empty" do
      lambda { resolver({}).app_environment }.should raise_error(ArgumentError)
    end

    it "raises when there is no app match" do
      lambda { resolver(:environment_name => 'app_dup', :app_name => 'gibberish').app_environment }.should raise_error(EY::CloudClient::InvalidAppError)
    end

    it "raises when there is no environment match" do
      lambda { resolver(:environment_name => 'gibberish', :app_name => 'app').app_environment }.should raise_error(EY::CloudClient::NoEnvironmentError)
    end

    it "raises when there are no matches" do
      lambda { resolver(:environment_name => 'app_dup', :app_name => 'bigapp'                         ).app_environment }.should raise_error(EY::CloudClient::NoMatchesError)
      lambda { resolver(:environment_name => 'app_dup', :repo => repo("git://github.com/repo/app.git")).app_environment }.should raise_error(EY::CloudClient::NoMatchesError)
    end

    it "raises when there is more than one match" do
      lambda { resolver(:app_name => "app"                            ).app_environment }.should raise_error(EY::CloudClient::MultipleMatchesError)
      lambda { resolver(:account_name => "ey", :app_name => "app"     ).app_environment }.should raise_error(EY::CloudClient::MultipleMatchesError)
      lambda { resolver(:repo => repo("git://github.com/repo/dup.git")).app_environment }.should raise_error(EY::CloudClient::MultipleMatchesError)
      lambda { resolver(:repo => repo("git://github.com/repo/app.git")).app_environment }.should raise_error(EY::CloudClient::MultipleMatchesError)
    end

    it "does not include duplicate copies of apps across accounts when raising a more than one match error" do
      do_include     = "--environment='sumo_wrestler' --app='app_dup' --account='ey'"
      do_not_include = "--environment='sumo_wrestler' --app='app_dup' --account='me'"
      lambda do
        resolver(:repo => repo("git://github.com/repo/dup.git")).app_environment
      end.should raise_error(EY::CloudClient::MultipleMatchesError) {|e|
        e.message.should include(do_include)
        e.message.should_not include(do_not_include)
      }
    end

    it "returns one deployment whene there is only one match" do
      resolver(:account_name => "ey", :app_name => "big"                                     ).app_environment.should == @big
      resolver(:environment_name => "production"                                             ).app_environment.should == @production
      resolver(:repo => repo("git://github.com/repo/big.git")                                ).app_environment.should == @big
      resolver(:repo => repo("git://github.com/repo/app.git"), :environment_name => "staging").app_environment.should == @staging
    end

    it "doesn't care about case" do
      resolver(:account_name => "EY", :app_name => "big").app_environment.should == @big
      resolver(:account_name => "ey", :app_name => "BiG").app_environment.should == @big
    end

    it "returns the match when an app is specified even when there is a repo" do
      resolver(:account_name => "ey", :app_name => "bigapp", :repo => repo("git://github.com/repo/app.git")).app_environment.should == @big
    end

    it "returns the specific match even if there is a partial match" do
      resolver(:environment_name => 'app_staging', :app_name => 'app').app_environment.should == @staging
      resolver(:environment_name => "app_staging"                    ).app_environment.should == @staging
      resolver(:app_name => "app", :environment_name => "staging"    ).app_environment.should == @staging
    end

    it "scopes searches under the correct account" do
      resolver(:account_name => "ey", :environment_name => "dup", :app_name => "dup").app_environment.should == @ey_dup
      resolver(:account_name => "me", :environment_name => "dup"                    ).app_environment.should == @me_dup
      resolver(:account_name => "me",                             :app_name => "dup").app_environment.should == @me_dup
    end
  end
end
