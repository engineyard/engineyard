require 'spec_helper'

describe EY::Repo do
  let(:path) { p = Pathname.new(Dir.tmpdir).join('ey-test'); p.mkpath; p }

  before(:each) do
    Dir.chdir(path) { `git init -q` }
    ENV['GIT_DIR'] = path.join('.git').to_s
  end

  after(:each) do
    EY.reset
    path.rmtree
    ENV.delete('GIT_DIR')
  end

  def set_head(head)
    path.join('.git','HEAD').open('w') {|f| f.write(head) }
  end

  def set_url(url, remote)
    `git remote add #{remote} #{url}`
  end

  describe "current_branch method" do
    it "returns the name of the current branch" do
      set_head "ref: refs/heads/master"
      EY.repo.current_branch.should == "master"
    end

    it "returns nil if there is no current branch" do
      set_head "20bf478ab6a91ec5771130aa4c8cfd3d150c4146"
      EY.repo.current_branch.should be_nil
    end
  end # current_branch

  describe "#fail_on_no_remotes!" do
    it "raises when there are no remotes" do
      lambda { EY.repo.fail_on_no_remotes! }.should raise_error(EY::NoRemotesError)
    end
  end

  describe "#has_remote?" do
    it "returns the urls of the remotes" do
      origin_url = "git://github.com/engineyard/engineyard.git"
      other_url = "git@github.com:engineyard/engineyard.git"
      set_url origin_url, "origin"
      set_url other_url,  "other"
      EY.repo.should have_remote(origin_url)
      EY.repo.should have_remote(other_url)
    end
  end # url

end # EY::Repo
