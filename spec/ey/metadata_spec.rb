require 'spec_helper'

describe "ey metadata" do

  given "integration"

  before(:all) do
    api_scenario "one app, one environment"
  end

  it 'lists available metadata keys' do
    ey 'metadata --keys'
    EY::Model::Metadata::KEYS.each do |key|
      @out.should =~ /#{key}\n/
    end
  end
  
  it 'prints nothing if the key is not valid' do
    lambda {
      ey 'metadata dofijsdf'
    }.should_not raise_error
  end

  it 'prints the database host' do
    ey 'metadata database_host'
    @out.should =~ /\ndb_master_hostname.compute-1.amazonaws.com\n\z/
  end

  it 'prints the app server hostnames' do
    ey 'metadata app_servers'
    @out.should =~ /\napp_hostname.compute-1.amazonaws.com,app_master_hostname.compute-1.amazonaws.com\n\z/
  end

  it 'prints the db server hostnames' do
    ey 'metadata db_servers'
    @out.should =~ /\ndb_master_hostname.compute-1.amazonaws.com,db_slave_1_hostname.compute-1.amazonaws.com,db_slave_2_hostname.compute-1.amazonaws.com\n\z/
  end

  it 'prints the utility server hostnames' do
    ey 'metadata utilities'
    @out.should =~ /\nutil_fluffy_hostname.compute-1.amazonaws.com,util_rocky_hostname.compute-1.amazonaws.com\n\z/
  end
  
  it 'prints the hostname of the db master' do
    ey 'metadata db_master'
    @out.should =~ /\ndb_master_hostname.compute-1.amazonaws.com\n\z/
  end
  
  it 'prints the hostname of the app master' do
    ey 'metadata app_master'
    @out.should =~ /\napp_master_hostname.compute-1.amazonaws.com\n\z/
  end
  
  it 'prints helpful SSH aliases' do
    ey 'metadata ssh_aliases'
    @out.should =~ /Host giblets-app_master\n  Hostname app_master_hostname.compute-1.amazonaws.com/
  end

  # Not currently available
  # it 'prints the db password' do
  #   ey 'metadata database_password'
  #   @out.should =~ /\nGOBBER\n/
  # end  
end

describe "ey metadata with multiple environments" do

  given "integration"

  before(:all) do
    api_scenario "one app, many environments"
  end

  it 'prints the solo host' do
    ey 'metadata solo --environment giblets'
    @out.should =~ /\napp_master_hostname.compute-1.amazonaws.com\n\z/
  end

  it 'prints the db host' do
    ey 'metadata database_host --environment giblets'
    @out.should =~ /\napp_master_hostname.compute-1.amazonaws.com\n\z/
  end
  
  it 'prints the db master' do
    ey 'metadata db_master --environment giblets'
    @out.should =~ /\napp_master_hostname.compute-1.amazonaws.com\n\z/
  end
  
  it 'prints the app server hostnames' do
    ey 'metadata app_servers --environment giblets'
    @out.should =~ /\napp_master_hostname.compute-1.amazonaws.com\n\z/
  end

  it 'prints the db server hostnames' do
    ey 'metadata db_servers --environment giblets'
    @out.should =~ /\napp_master_hostname.compute-1.amazonaws.com\n\z/
  end

  it 'prints the utility server hostnames' do
    ey 'metadata utilities --environment giblets'
    @out.should =~ /\napp_master_hostname.compute-1.amazonaws.com\n\z/
  end

  it 'prints helpful SSH aliases' do
    ey 'metadata ssh_aliases --environment giblets'
    @out.should =~ /Host giblets-app_master\n  Hostname app_master_hostname.compute-1.amazonaws.com/
  end

  # Not currently available
  # it 'prints the db password' do
  #   ey 'metadata database_password --environment giblets'
  #   @out.should =~ /\nGOBBER\n/
  # end
end
