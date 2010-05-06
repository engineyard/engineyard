require 'spec_helper'

describe EY::Account do
  it_should_behave_like "it has an account"

  it "returns instances" do
    @env = EY::Account::Environment.from_hash({
      "id" => 1, "name" => "banana", "instances_count" => 3,
      "ssh_username" => "monkey", "apps" => {}, "account" => @account
    })
    @instance_data = {"id" => "1", "role" => "app_master",
      "amazon_id" => "amazon_1", "public_hostname" => "banana_master"}
    FakeWeb.register_uri(:get, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/instances",
      :body => {"instances" => [@instance_data]}.to_json)

    @account.instances_for(@env).first.should == EY::Account::Instance.from_hash(@instance_data)
  end
end
