require 'spec_helper'

describe EY::Repo do
  before(:all) do
    FakeFS.deactivate!
    @path = Pathname.new("/tmp/ey-test/.git/")
    @r = EY::Repo.new("/tmp/ey-test")
  end
  after(:all) { FakeFS.activate! }
  after(:each) { clear_urls }

  def set_head(head)
    @path.join("HEAD").open('w') {|f| f.write(head) }
  end

  def config_path
    @path.join("config")
  end

  def set_url(url, remote)
    system("mkdir -p #{@path} && cd #{@path} && git init -q")
    system("git config -f #{config_path} remote.#{remote}.url #{url}")
  end

  def clear_urls
    system("rm -rf #{config_path}")
  end

  describe "current_branch method" do
    it "returns the name of the current branch" do
      set_head "ref: refs/heads/master"
      @r.current_branch.should == "master"
    end

    it "returns nil if there is no current branch" do
      set_head "20bf478ab6a91ec5771130aa4c8cfd3d150c4146"
      @r.current_branch.should be_nil
    end
  end # current_branch

  describe "#fail_on_no_remotes!" do
    it "raises when there are no remotes" do
      lambda { @r.fail_on_no_remotes! }.should raise_error(EY::NoRemotesError)
    end
  end

  describe "#has_remote?" do
    it "returns the urls of the remotes" do
      origin_url = "git://github.com/engineyard/engineyard.git"
      other_url = "git@github.com:engineyard/engineyard.git"
      set_url origin_url, "origin"
      set_url other_url,  "other"
      @r.should be_has_remote(origin_url)
      @r.should be_has_remote(other_url)
    end
  end # url

end # EY::Repo
