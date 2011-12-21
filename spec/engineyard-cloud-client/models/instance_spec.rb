require 'spec_helper'

describe EY::CloudClient::Instance do
  it "is true for solos" do
    EY::CloudClient::Instance.from_hash(ey_api, "role" => "solo").should have_app_code
  end

  it "is true for app masters" do
    EY::CloudClient::Instance.from_hash(ey_api, "role" => "app_master").should have_app_code
  end

  it "is true for app slaves" do
    EY::CloudClient::Instance.from_hash(ey_api, "role" => "app").should have_app_code
  end

  it "is true for utilities" do
    EY::CloudClient::Instance.from_hash(ey_api, "role" => "util").should have_app_code
  end

  it "is false for DB masters" do
    EY::CloudClient::Instance.from_hash(ey_api, "role" => "db_master").should_not have_app_code
  end

  it "is false for DB slaves" do
    EY::CloudClient::Instance.from_hash(ey_api, "role" => "db_slave").should_not have_app_code
  end
end
