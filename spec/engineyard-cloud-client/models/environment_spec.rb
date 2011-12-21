require 'spec_helper'

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

describe "EY::CloudClient::Environment.from_array" do
  it "returns a smart collection, not just a dumb array" do
    api_data = [
      {"id" => 32340, "name" => 'iceberg'},
      {"id" => 9433, "name" => 'zoidberg'},
    ]

    collection = EY::CloudClient::Environment.from_array(ey_api, api_data)
    collection.should respond_to(:each)
    collection.should respond_to(:match_one)
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
