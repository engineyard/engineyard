require 'spec_helper'

describe "EY::CloudClient::App.create" do
  it "hits the create action in the API" do
    account = EY::CloudClient::Account.new(ey_api, {:id => 1234, :name => 'myaccount'})

    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/accounts/1234/apps", :body => '')

    app = EY::CloudClient::App.create(ey_api, account, 'myapp2', 'git@github.com:myaccount/myapp2.git', 'rails3')

    FakeWeb.should have_requested(:post, "https://cloud.engineyard.com/api/v2/accounts/1234/apps")
  end
end
