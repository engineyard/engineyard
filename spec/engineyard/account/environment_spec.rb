require 'spec_helper'

describe "EY::Account::Environment#rebuild" do
  it_should_behave_like "it has an account"

  it "hits the rebuild action in the API" do
    env = EY::Account::Environment.from_hash({
        "id" => 46534,
        "account" => @account
      })

    FakeWeb.register_uri(:put,
      "https://cloud.engineyard.com/api/v2/environments/#{env.id}/rebuild",
      :body => {}.to_json)

    env.rebuild

    FakeWeb.should have_requested(:put, "https://cloud.engineyard.com/api/v2/environments/#{env.id}/rebuild")
  end
end
