require 'spec_helper'

describe "EY::CloudClient::Environment.all" do
  it "hits the index action in the API" do
    response = {
      "environments" => [
        {"apps"=>
          [{"name"=>"myapp",
            "repository_uri"=>"git@github.com:myaccount/myapp.git",
            "account"=>{"name"=>"myaccount", "id"=>1234},
            "id"=>12345}],
         "name"=>"myapp_production",
         "deployment_configurations"=>
          {"myapp"=>
            {"name"=>"myapp",
             "uri"=>nil,
             "migrate"=>{"command"=>"rake db:migrate", "perform"=>true},
             "repository_uri"=>"git@github.com:myaccount/myapp.git",
             "id"=>12345,
             "domain_name"=>"_"}},
         "instances"=>[],
         "app_master"=>nil,
         "framework_env"=>"production",
         "stack_name"=>"nginx_thin",
         "account"=>{"name"=>"myaccount", "id"=>1234},
         "app_server_stack_name"=>"nginx_thin",
         "ssh_username"=>"deploy",
         "load_balancer_ip_address"=>nil,
         "instances_count"=>0,
         "id"=>30573,
         "instance_status"=>"none"
        }
      ]
    }

    FakeWeb.register_uri(:get, "https://cloud.engineyard.com/api/v2/environments",
      :body => response.to_json, :content_type => "application/json")

    environments = EY::CloudClient::Environment.all(ey_api)

    environments.length.should == 1
    environments.first.name.should == "myapp_production"
  end
end

describe "EY::CloudClient::Environment.create" do
  it "hits the create action in the API without any cluster configuration (0 instances booted)" do
    account = EY::CloudClient::Account.new(ey_api, {:id => 1234, :name => 'myaccount'})
    app = EY::CloudClient::App.new(ey_api, {:account => account, :id => 12345, :name => 'myapp',
      :repository_uri => 'git@github.com:myaccount/myapp.git', :app_type_id => 'rails3'})

    response =   {
      "environment"=>
        {"apps"=>
          [{"name"=>"myapp",
            "repository_uri"=>"git@github.com:myaccount/myapp.git",
            "account"=>{"name"=>"myaccount", "id"=>1234},
            "id"=>12345}],
         "name"=>"myapp_production",
         "deployment_configurations"=>
          {"myapp"=>
            {"name"=>"myapp",
             "uri"=>nil,
             "migrate"=>{"command"=>"rake db:migrate", "perform"=>true},
             "repository_uri"=>"git@github.com:myaccount/myapp.git",
             "id"=>12345,
             "domain_name"=>"_"}},
         "instances"=>[],
         "app_master"=>nil,
         "framework_env"=>"production",
         "stack_name"=>"nginx_thin",
         "account"=>{"name"=>"myaccount", "id"=>1234},
         "app_server_stack_name"=>"nginx_thin",
         "ssh_username"=>"deploy",
         "load_balancer_ip_address"=>nil,
         "instances_count"=>0,
         "id"=>30573,
         "instance_status"=>"none"}}

    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/apps/12345/environments",
      :body => response.to_json, :content_type => "application/json")

    env = EY::CloudClient::Environment.create(ey_api, {
      "app"                   => app,
      "name"                  => 'myapp_production',
      "app_server_stack_name" => 'nginx_thin',
      "region"                => 'us-west-1'
    })
    FakeWeb.should have_requested(:post, "https://cloud.engineyard.com/api/v2/apps/12345/environments")

    env.name.should == "myapp_production"
    env.account.name.should == "myaccount"
    env.apps.to_a.first.name.should == "myapp"
  end

  it "hits the create action and requests a solo instance booted" do
    account = EY::CloudClient::Account.from_hash(ey_api, {:id => 1234, :name => 'myaccount'})
    app = EY::CloudClient::App.from_hash(ey_api, {:account => account, :id => 12345, :name => 'myapp',
      :repository_uri => 'git@github.com:myaccount/myapp.git', :app_type_id => 'rails3'})

    response =   {
      "environment"=>
        {"apps"=>
          [{"name"=>"myapp",
            "repository_uri"=>"git@github.com:myaccount/myapp.git",
            "account"=>{"name"=>"myaccount", "id"=>1234},
            "id"=>12345}],
         "name"=>"myapp_production",
         "deployment_configurations"=>
          {"myapp"=>
            {"name"=>"myapp",
             "uri"=>nil,
             "migrate"=>{"command"=>"rake db:migrate", "perform"=>true},
             "repository_uri"=>"git@github.com:myaccount/myapp.git",
             "id"=>12345,
             "domain_name"=>"_"}},
         "instances"=>
           [{"public_hostname"=>nil,
             "name"=>nil,
             "amazon_id"=>nil,
             "role"=>"solo",
             "id"=>135930,
             "status"=>"starting"}],
          "app_master"=>
           {"public_hostname"=>nil,
            "name"=>nil,
            "amazon_id"=>nil,
            "role"=>"solo",
            "id"=>135930,
            "status"=>"starting"},
         "framework_env"=>"production",
         "stack_name"=>"nginx_thin",
         "account"=>{"name"=>"myaccount", "id"=>1234},
         "app_server_stack_name"=>"nginx_thin",
         "ssh_username"=>"deploy",
         "load_balancer_ip_address"=>"50.18.248.18",
         "instances_count"=>1,
         "id"=>30573,
         "instance_status"=>"starting"}}

    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/apps/12345/environments",
      :body => response.to_json, :content_type => "application/json")

    env = EY::CloudClient::Environment.create(ey_api, {
      "app"                   => app,
      "name"                  => "myapp_production",
      "app_server_stack_name" => "nginx_thin",
      "region"                => "us-west-1",
      "cluster_configuration" => {
        "configuration" => "solo"
      }
    })
    FakeWeb.should have_requested(:post, "https://cloud.engineyard.com/api/v2/apps/12345/environments")

    env.name.should == "myapp_production"
    env.instances.count.should == 1
    env.app_master.role.should == "solo"
  end
end

describe "EY::CloudClient::Environment#destroy" do
  it "hits the destroy action in the API" do
    pending
  end
end

describe "EY::CloudClient::Environment#rebuild" do
  it "hits the rebuild action in the API" do
    env = EY::CloudClient::Environment.from_hash(ey_api, { "id" => 46534 })

    FakeWeb.register_uri(
      :put,
      "https://cloud.engineyard.com/api/v2/environments/#{env.id}/update_instances",
      :body => ''
    )

    env.rebuild

    FakeWeb.should have_requested(:put, "https://cloud.engineyard.com/api/v2/environments/#{env.id}/update_instances")
  end
end

describe "EY::CloudClient::Environment#run_custom_recipes" do
  it "hits the rebuild action in the API" do
    env = EY::CloudClient::Environment.from_hash(ey_api, { "id" => 46534 })

    FakeWeb.register_uri(
      :put,
      "https://cloud.engineyard.com/api/v2/environments/#{env.id}/run_custom_recipes",
      :body => '',
      :content_type => 'application/json'
    )

    env.run_custom_recipes

    FakeWeb.should have_requested(:put, "https://cloud.engineyard.com/api/v2/environments/#{env.id}/run_custom_recipes")
  end
end

describe "EY::CloudClient::Environment#instances" do
  it "returns instances" do
    instance_data = {
      "id" => "1",
      "role" => "app_master",
      "amazon_id" => "i-likebeer",
      "public_hostname" => "banana_master"
    }

    env = EY::CloudClient::Environment.from_hash(ey_api, {
      "id" => 10291,
      "instances" => [instance_data],
    })

    FakeWeb.register_uri(:get,
      "https://cloud.engineyard.com/api/v2/environments/#{env.id}/instances",
      :body => {"instances" => [instance_data]}.to_json,
      :content_type => 'application/json'
    )

    env.should have(1).instances
    env.instances.first.should == EY::CloudClient::Instance.from_hash(ey_api, instance_data.merge('environment' => env))
  end
end

describe "EY::CloudClient::Environment#app_master!" do
  def make_env_with_master(app_master)
    if app_master
      app_master = {
        "id" => 44206,
        "role" => "solo",
      }.merge(app_master)
    end

    EY::CloudClient::Environment.from_hash(ey_api, {
      "id" => 11830,
      "name" => "guinea-pigs-are-delicious",
      "app_master" => app_master,
      "instances" => [app_master].compact,
    })
  end


  it "returns the app master if it's present and running" do
    env = make_env_with_master("status" => "running")
    env.app_master!.should_not be_nil
    env.app_master!.id.should == 44206
  end

  it "raises an error if the app master is in a non-running state" do
    env = make_env_with_master("status" => "error")
    lambda {
      env.app_master!
    }.should raise_error(EY::CloudClient::BadAppMasterStatusError)
  end

  it "returns the app master if told to ignore the app master being in a non-running state" do
    env = make_env_with_master("status" => "error")
    env.ignore_bad_master = true
    env.app_master!.should_not be_nil
    env.app_master!.id.should == 44206
  end

  it "raises an error if the app master is absent" do
    env = make_env_with_master(nil)
    lambda {
      env.app_master!
    }.should raise_error(EY::CloudClient::NoAppMasterError)
  end
end

describe "EY::CloudClient::Environment#shorten_name_for(app)" do
  def short(environment_name, app_name)
    env = EY::CloudClient::Environment.from_hash(ey_api, {'name' => environment_name})
    app = EY::CloudClient::App.from_hash(ey_api, {'name' => app_name})
    env.shorten_name_for(app)
  end

  it "turns myapp+myapp_production to production" do
    short('myapp_production', 'myapp').should == 'production'
  end

  it "turns product+production to production (leaves it alone)" do
    short('production', 'product').should == 'production'
  end

  it "leaves the environment name alone when the app name appears in the middle" do
    short('hattery', 'ate').should == 'hattery'
  end

  it "does not produce an empty string when the names are the same" do
    short('dev', 'dev').should == 'dev'
  end
end
