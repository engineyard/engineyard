require 'spec_helper'

describe "ey recipes upload" do
  given "integration"

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

  include_examples "it takes an environment name and an account name"
end

describe "ey recipes upload -f recipes.tgz" do
  given "integration"

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

  include_examples "it takes an environment name and an account name"
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
    login_scenario "one app, one environment"
    fast_failing_ey(%w[recipes upload --environment giblets -f recipes.tgz])
    @err.should match(/Recipes file not found: recipes.tgz/i)
  end
end

describe "ey recipes upload with an ambiguous git repo" do
  given "integration"
  def command_to_run(_) %w[recipes upload] end
  include_examples "it requires an unambiguous git repo"
end

describe "ey recipes upload from a separate cookbooks directory" do
  given "integration"

  context "without any git remotes" do
    use_git_repo "only cookbooks, no remotes"

    it "takes the environment specified by -e" do
      login_scenario "one app, one environment"

      ey %w[recipes upload -e giblets]
      @out.should =~ %r|Recipes in cookbooks/ uploaded successfully|
      @out.should_not =~ /Uploaded recipes started for giblets/
    end

    it "applies the recipes with --apply" do
      login_scenario "one app, one environment"

      ey %w[recipes upload -e giblets --apply]
      @out.should =~ %r|Recipes in cookbooks/ uploaded successfully|
      @out.should =~ /Uploaded recipes started for giblets/
    end
  end

  context "with a git remote unrelated to any application" do
    use_git_repo "only cookbooks, unrelated remotes"

    it "takes the environment specified by -e" do
      login_scenario "one app, one environment"

      ey %w[recipes upload -e giblets]
      @out.should =~ %r|Recipes in cookbooks/ uploaded successfully|
    end

  end
end
