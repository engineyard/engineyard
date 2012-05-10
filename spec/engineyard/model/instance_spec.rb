require 'spec_helper'

describe "EY::Model::Instance#has_app_code?" do
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

describe "EY::Model::Instance#calculate_options_for_ssh" do
  before do
    @instance = EY::Model::Instance.from_hash("role" => "solo")
  end

  it "works, with DEBUG=true" do
    ENV["DEBUG"] = "true"
    opts = @instance.send(:calculate_options_for_ssh, false)
    opts[:verbose].should eq :debug
  end
  it "works, with DEBUG one of [debug, info, warn, error, fatal]" do
    %w( debug info warn error fatal ).each do |level|
      ENV["DEBUG"] = level
      opts = @instance.send(:calculate_options_for_ssh, false)
      opts[:verbose].should eq level.to_sym
    end
  end
  it "works, with no debug, but with --verbose specified" do
    ENV["DEBUG"] = nil
    opts = @instance.send(:calculate_options_for_ssh, true)
    opts[:verbose].should eq :debug
  end
  it "works, with no DEBUG or --verbose" do
    ENV["DEBUG"] = nil
    opts = @instance.send(:calculate_options_for_ssh, false)
    opts[:verbose].should be_nil
  end


end
