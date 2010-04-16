require 'rubygems'
require 'sinatra/base'
require 'json'

class FakeAwsm < Sinatra::Base
  before { content_type "application/json" }

  get "/" do
    content_type :html
    "OMG"
  end

  post "/api/v2/authenticate" do
    if valid_user?
      {"api_token" => "deadbeef", "ok" => true}.to_json
    else
      status(401)
      {"ok" => false}.to_json
    end
  end

private

  def valid_user?
    params[:email] == "test@test.test" &&
      params[:password] == "test"
  end

end

run FakeAwsm