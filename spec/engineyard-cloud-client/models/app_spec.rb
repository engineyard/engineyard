require 'spec_helper'

describe "EY::CloudClient::App.create" do
  it "hits the create app action in the API" do
    account = EY::CloudClient::Account.new(ey_api, {:id => 1234, :name => 'myaccount'})

    response = {
      "app"=>{
        "environments"=>[],
        "name"=>"myapp",
        "repository_uri"=>"git@github.com:myaccount/myapp.git",
        "account"=>{"name"=>"myaccount", "id"=>1234},
        "id"=>12345
      }
    }

    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/accounts/1234/apps",
      :body => response.to_json, :content_type => "application/json")

    app = EY::CloudClient::App.create(ey_api, {
      :account => account,
      :name => 'myapp',
      'repository_uri' => 'git@github.com:myaccount/myapp.git',
      :app_type_id => 'rails3'
    })

    FakeWeb.should have_requested(:post, "https://cloud.engineyard.com/api/v2/accounts/1234/apps")

    app.name.should == "myapp"
    app.account.name.should == "myaccount"
  end
end
