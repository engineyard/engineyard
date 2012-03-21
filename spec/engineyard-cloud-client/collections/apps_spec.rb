require 'spec_helper'

describe EY::CloudClient::Collections::Apps do
  before do
    @collection_class = EY::CloudClient::Collections::Apps
    @collection = @collection_class.new([
      EY::CloudClient::App.from_hash(ey_api, "id" => 1234, "name" => "app_production"),
      EY::CloudClient::App.from_hash(ey_api, "id" => 4321, "name" => "app_staging"),
      EY::CloudClient::App.from_hash(ey_api, "id" => 8765, "name" => "bigapp_staging"),
      EY::CloudClient::App.from_hash(ey_api, "id" => 4532, "name" => "app_duplicate"),
      EY::CloudClient::App.from_hash(ey_api, "id" => 4533, "name" => "app_duplicate"),
    ])
  end

  include_examples "model collections"
end
