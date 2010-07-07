require 'spec_helper'

describe "EY::Model::Instance#has_app_code?" do

  def have_app_code
    simple_matcher("has app code") { |given| given.has_app_code? }
  end

  it "is true for solos" do
    EY::Model::Instance.from_hash("role" => "solo").should have_app_code
  end

  it "is true for app masters" do
    EY::Model::Instance.from_hash("role" => "app_master").should have_app_code
  end

  it "is true for app slaves" do
    EY::Model::Instance.from_hash("role" => "app").should have_app_code
  end

  it "is true for utilities" do
    EY::Model::Instance.from_hash("role" => "util").should have_app_code
  end

  it "is false for DB masters" do
    EY::Model::Instance.from_hash("role" => "db_master").should_not have_app_code
  end

  it "is false for DB slaves" do
    EY::Model::Instance.from_hash("role" => "db_slave").should_not have_app_code
  end
end
