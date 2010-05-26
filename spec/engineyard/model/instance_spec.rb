require 'spec_helper'

describe "EY::Model::Instance's script for checking ey-deploy's version" do

  def fake_out_no_ey_deploy
    Gem.should_receive(:source_index).and_return(Gem::SourceIndex.new)
  end

  def fake_out_installed_ey_deploy_version(version)
    net_sftp_gem = Gem::Specification.new do |s|
      s.authors = ["Jamis Buck"]
      s.autorequire = "net/sftp"
      s.date = Time.utc(2008, 2, 24)
      s.email = "jamis@jamisbuck.org"
      s.files = ["doc/faq",
        # snip
        "test/protocol/tc_driver.rb"]
      s.homepage = "http://net-ssh.rubyforge.org/sftp"
      s.name = "net-sftp"
      s.require_paths = ["lib"]
      s.rubygems_version = "1.3.5"
      s.specification_version = 2
      s.summary = "Net::SFTP is a pure-Ruby implementation of the SFTP client protocol."
      s.test_files = ["test/ALL-TESTS.rb"]
      s.version = Gem::Version.new("1.1.1")
    end

    ey_deploy_gem = Gem::Specification.new do |s|
      s.name = 'ey-deploy'
      s.authors = ["EY Cloud Team"]
      s.date = Time.utc(2010, 1, 2)
      s.files = ['lib/engineyard/ey-deploy.rb'] # or something
      s.specification_version = 2
      s.version = Gem::Version.new(version)
    end

    fake_source_index = Gem::SourceIndex.new(
      'net-sftp-1.1.1' => net_sftp_gem,
      "ey-deploy-#{version}" => ey_deploy_gem
      )
    Gem.should_receive(:source_index).and_return(fake_source_index)
  end

  def script_exit_status
    eval EY::Model::Instance::CHECK_SCRIPT
  rescue SystemExit => e
    return e.status
  end

  it "exits 104 if the ey-deploy gem is not installed" do
    fake_out_no_ey_deploy
    script_exit_status.should == 104
  end

  it "exits 70 if the installed ey-deploy is too old" do
    fake_out_installed_ey_deploy_version('0.0.1')
    script_exit_status.should == 70
  end

  it "exits 17 if the installed ey-deploy is too new" do
    fake_out_installed_ey_deploy_version('1000.0.0')
    script_exit_status.should == 17
  end

  it "exits 0 if the version number is correct" do
    correct_version = EY::Model::Instance::EYSD_VERSION.gsub(/[^\d\.]/, '')
    fake_out_installed_ey_deploy_version(correct_version)
    script_exit_status.should == 0
  end
end
