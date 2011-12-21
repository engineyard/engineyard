require 'spec_helper'

describe EY::CloudClient::Collections::Environments do
  before do
    @collection_class = EY::CloudClient::Collections::Environments
    @collection = @collection_class.new([
      EY::CloudClient::Environment.from_hash(ey_api, "id" => 1234, "name" => "app_production"),
      EY::CloudClient::Environment.from_hash(ey_api, "id" => 4321, "name" => "app_staging"),
      EY::CloudClient::Environment.from_hash(ey_api, "id" => 8765, "name" => "bigapp_staging"),
      EY::CloudClient::Environment.from_hash(ey_api, "id" => 4532, "name" => "app_duplicate"),
      EY::CloudClient::Environment.from_hash(ey_api, "id" => 4533, "name" => "app_duplicate"),
    ])
  end

  include_examples "model collections"
end
