require 'spec_helper'

describe "ey recipes upload" do
  given "integration"

  define_git_repo('+cookbooks') do |git_dir|
    git_dir.join("cookbooks").mkdir
    File.open(git_dir.join("cookbooks/file"), "w"){|f| f << "boo" }
  end
  use_git_repo('+cookbooks')

  def command_to_run(opts)
    cmd = %w[recipes upload]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd
  end

  def verify_ran(scenario)
    @out.should =~ %r|Recipes in cookbooks/ uploaded successfully for #{scenario[:environment]}|
  end

  it_should_behave_like "it takes an environment name and an account name"
end

describe "ey recipes upload -f recipes.tgz" do
  given "integration"

  define_git_repo('+recipes') do |git_dir|
    link_recipes_tgz(git_dir)
  end
  use_git_repo('+recipes')

  def command_to_run(opts)
    cmd = %w[recipes upload]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd << "-f" << "recipes.tgz"
    cmd
  end

  def verify_ran(scenario)
    @out.should =~ %r|Recipes file recipes.tgz uploaded successfully for #{scenario[:environment]}|
  end

  it_should_behave_like "it takes an environment name and an account name"
end

describe "ey recipes upload -f with a missing filenamen" do
  given "integration"
  def command_to_run(opts)
    cmd = %w[recipes upload]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd << "-f" << "recipes.tgz"
    cmd
  end

  it "errors with file not found" do
    api_scenario "one app, one environment"
    ey(%w[recipes upload --environment giblets -f recipes.tgz], :expect_failure => true)
    @err.should match(/Recipes file not found: recipes.tgz/i)
  end
end

describe "ey recipes upload with an ambiguous git repo" do
  given "integration"
  def command_to_run(_) %w[recipes upload] end
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

      ey %w[recipes upload -e giblets]
      @out.should =~ %r|Recipes in cookbooks/ uploaded successfully|
      @out.should_not =~ /Uploaded recipes started for giblets/
    end

    it "applies the recipes with --apply" do
      api_scenario "one app, one environment"

      ey %w[recipes upload -e giblets --apply]
      @out.should =~ %r|Recipes in cookbooks/ uploaded successfully|
      @out.should =~ /Uploaded recipes started for giblets/
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

      ey %w[recipes upload -e giblets]
      @out.should =~ %r|Recipes in cookbooks/ uploaded successfully|
    end

  end
end
