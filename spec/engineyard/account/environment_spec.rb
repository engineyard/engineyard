require 'spec_helper'

describe "EY::Model::Environment#rebuild" do
  it_should_behave_like "it has an api"

  it "hits the rebuild action in the API" do
    env = EY::Model::Environment.from_hash({
        "id" => 46534,
        "api" => @api,
      })

    FakeWeb.register_uri(:put,
      "https://cloud.engineyard.com/api/v2/environments/#{env.id}/rebuild",
      :body => {}.to_json)

    env.rebuild

    FakeWeb.should have_requested(:put, "https://cloud.engineyard.com/api/v2/environments/#{env.id}/rebuild")
  end
end

describe "EY::Model::Environment#instances" do
  it_should_behave_like "it has an api"

  it "returns instances" do
    env = EY::Model::Environment.from_hash({
        "id" => 10291,
        "api" => @api,
      })

    instance_data = {
      "id" => "1",
      "role" => "app_master",
      "amazon_id" => "i-likebeer",
      "public_hostname" => "banana_master"
    }
    FakeWeb.register_uri(:get,
      "https://cloud.engineyard.com/api/v2/environments/#{env.id}/instances",
      :body => {"instances" => [instance_data]}.to_json)


    env.should have(1).instances
    env.instances.first.should == EY::Model::Instance.from_hash(instance_data.merge(:environment => env))
  end
end
