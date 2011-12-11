require 'spec_helper'

describe EY::APIClient::Collections::Apps do
  before do
    @collection_class = EY::APIClient::Collections::Apps
    @collection = @collection_class.new([
      EY::APIClient::App.from_hash("id" => 1234, "name" => "app_production"),
      EY::APIClient::App.from_hash("id" => 4321, "name" => "app_staging"),
      EY::APIClient::App.from_hash("id" => 8765, "name" => "bigapp_staging"),
      EY::APIClient::App.from_hash("id" => 4532, "name" => "app_duplicate"),
      EY::APIClient::App.from_hash("id" => 4533, "name" => "app_duplicate"),
    ])
  end

  include_examples "model collections"
end
