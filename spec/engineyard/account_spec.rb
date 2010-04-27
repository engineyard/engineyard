require 'spec_helper'

describe EY::Account do
  before(:each) do
    write_yaml({"api_token" => "asdf"}, '~/.eyrc')
    @account = EY::Account.new(EY::API.new)
  end

  it "returns instances" do
    @env = EY::Account::Environment.from_hash({
      "id" => 1, "name" => "banana", "instances_count" => 3,
      "ssh_username" => "monkey", "apps" => {}
    }, @account)
    @instance_data = {"id" => "1", "role" => "app_master",
      "amazon_id" => "amazon_1", "public_hostname" => "banana_master"}
    FakeWeb.register_uri(:get, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/instances",
      :body => {"instances" => [@instance_data]}.to_json)

    @account.instances_for(@env).first.should == Instance.from_hash(@instance_data)
  end
end