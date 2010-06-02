require 'spec_helper'

describe EY::Collection::Environments do
  before(:each) do
    @envs = described_class.new([
      EY::Model::Environment.from_hash("id" => 1234, "name" => "app_production"),
      EY::Model::Environment.from_hash("id" => 4321, "name" => "app_staging"),
      EY::Model::Environment.from_hash("id" => 8765, "name" => "bigapp_staging"),
    ])
  end

  describe "#match_one" do
    it "works when given an unambiguous substring" do
      @envs.match_one("prod").name.should == "app_production"
    end

    it "raises an error when given an ambiguous substring" do
      lambda {
        @envs.match_one("staging")
      }.should raise_error(EY::AmbiguousEnvironmentName)
    end

    it "returns an exact match if one exists" do
      @envs.match_one("app_staging").name.should == "app_staging"
    end

    it "returns nil when it can't find anything" do
      @envs.match_one("dev-and-production").should be_nil
    end
  end

  describe "#match_one!" do
    it "works when given an unambiguous substring" do
      @envs.match_one!("prod").name.should == "app_production"
    end

    it "raises an error when given an ambiguous substring" do
      lambda {
        @envs.match_one!("staging")
      }.should raise_error(EY::AmbiguousEnvironmentName)
    end

    it "returns an exact match if one exists" do
      @envs.match_one!("app_staging").name.should == "app_staging"
    end

    it "raises an error when it can't find anything" do
      lambda {
        @envs.match_one!("dev-and-production")
      }.should raise_error(EY::EnvironmentError)
    end
  end

  describe "#named" do
    it "finds the environment with the matching name" do
      @envs.named("app_staging").id.should == 4321
    end

    it "returns nil when no name matches" do
      @envs.named("something else").should be_nil
    end
  end

  describe "#named!" do
    it "finds the environment with the matching name" do
      @envs.named!("app_staging").id.should == 4321
    end

    it "raises an error when no name matches" do
      lambda {
        @envs.named!("something else")
      }.should raise_error(EY::EnvironmentError)
    end
  end
end
