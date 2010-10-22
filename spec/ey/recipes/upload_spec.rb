require 'spec_helper'

describe "ey recipes upload" do
  given "integration"

  define_git_repo('+cookbooks') do |git_dir|
    git_dir.join("cookbooks").mkdir
    File.open(git_dir.join("cookbooks/file"), "w"){|f| f << "boo" }
  end
  use_git_repo('+cookbooks')

  def command_to_run(opts)
    cmd = "recipes upload"
    cmd << " --environment #{opts[:environment]}" if opts[:environment]
    cmd << " --account #{opts[:account]}" if opts[:account]
    cmd
  end

  def verify_ran(scenario)
    @out.should =~ /Recipes uploaded successfully for #{scenario[:environment]}/
  end

  it_should_behave_like "it takes an environment name and an account name"
end

describe "ey recipes upload with an ambiguous git repo" do
  given "integration"
  def command_to_run(_) "recipes upload" end
  it_should_behave_like "it requires an unambiguous git repo"
end

describe "ey recipes upload from a separate cookbooks directory" do
  given "integration"

  context "without any git remotes" do
    define_git_repo "only cookbooks, no remotes" do |git_dir|
      `git --git-dir "#{git_dir}/.git" remote`.split("\n").each do |remote|
        `git --git-dir "#{git_dir}/.git" remote rm #{remote}`
      end

      git_dir.join("cookbooks").mkdir
      File.open(git_dir.join("cookbooks/file"), "w"){|f| f << "stuff" }
    end

    use_git_repo "only cookbooks, no remotes"

    it "takes the environment specified by -e" do
      api_scenario "one app, one environment"

      ey "recipes upload -e giblets"
      @out.should =~ /Recipes uploaded successfully/
    end
  end

  context "with a git remote unrelated to any application" do
    define_git_repo "only cookbooks, unrelated remotes" do |git_dir|
      `git --git-dir "#{git_dir}/.git" remote`.split("\n").each do |remote|
        `git --git-dir "#{git_dir}/.git" remote rm #{remote}`
      end

      `git remote add origin polly@pirate.example.com:wanna/cracker.git`

      git_dir.join("cookbooks").mkdir
      File.open(git_dir.join("cookbooks/file"), "w"){|f| f << "rawk" }
    end

    use_git_repo "only cookbooks, unrelated remotes"

    it "takes the environment specified by -e" do
      api_scenario "one app, one environment"

      ey "recipes upload -e giblets"
      @out.should =~ /Recipes uploaded successfully/
    end

  end
end
