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

  describe "repo_url method" do
    it "returns the url of the origin remote" do
      origin_url = "git@github.com/engineyard/engineyard.git"
      set_repo_url origin_url
      @r.repo_url.should == origin_url
    end

    it "returns nil if there is no origin remote" do
      set_repo_url nil
      @r.repo_url.should be_nil
    end

    def set_repo_url(url)
      @config_path = @path+"config"
      # This has to all shell out because FakeFS is enabled
      if url
        system("mkdir -p #{@path} && cd #{@path} && git init -q")
        system("git config -f #{@config_path} remote.origin.url #{url}")
      else
        system("rm -rf #{@config_path}")
      end
    end
  end # repo_url

end # EY::Repo
