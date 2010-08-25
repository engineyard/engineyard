require 'spec_helper'

describe EY::Collection::Apps do
  before do
    @collection_class = EY::Collection::Apps
    @collection = @collection_class.new([
      EY::Model::App.from_hash("id" => 1234, "name" => "app_production"),
      EY::Model::App.from_hash("id" => 4321, "name" => "app_staging"),
      EY::Model::App.from_hash("id" => 8765, "name" => "bigapp_staging"),
      EY::Model::App.from_hash("id" => 4532, "name" => "app_duplicate"),
      EY::Model::App.from_hash("id" => 4533, "name" => "app_duplicate"),
    ])
  end

    it_should_behave_like "model collections"
end
