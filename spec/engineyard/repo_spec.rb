require 'spec_helper'

describe EY::Repo do
  before(:all) do
    @path = "/tmp/ey-test/.git/"
    @r = EY::Repo.new("/tmp/ey-test")
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

    def set_head(head)
      File.open(@path+"HEAD", "w"){|f| f.write(head) }
    end
  end # current_branch

  describe "urls method" do
    it "returns the urls of the remotes" do
      origin_url = "git://github.com/engineyard/engineyard.git"
      other_url = "git@github.com:engineyard/engineyard.git"
      set_url origin_url
      set_url other_url, "other"
      @r.urls.should include(origin_url)
      @r.urls.should include(other_url)
    end

    it "returns nil if there is no origin remote" do
      set_url nil
      @r.urls.should be_empty
    end

    def set_url(url, remote="origin")
      @config_path = @path+"config"
      # This has to all shell out because FakeFS is enabled
      if url
        system("mkdir -p #{@path} && cd #{@path} && git init -q")
        system("git config -f #{@config_path} remote.#{remote}.url #{url}")
      else
        system("rm -rf #{@config_path}")
      end
    end
  end # url

end # EY::Repo
