if self.class.const_defined?(:EY_ROOT)
  raise "don't require the spec helper twice!"
end

EY_ROOT = File.expand_path("../..", __FILE__)
begin
  require File.join(EY_ROOT, ".bundle/environment.rb")
rescue LoadError
  puts "Can't load bundler environment. You need to run `bundle lock`."
  exit
end

# Bundled gems
require 'fakeweb'
require 'fakeweb_matcher'
require 'fakefs/safe'
require 'json'

# Engineyard gem
$LOAD_PATH.unshift(File.join(EY_ROOT, "lib"))
require 'engineyard'

# Spec stuff
require 'spec/autorun'
require 'yaml'
require 'pp'
support = Dir[File.join(EY_ROOT,'/spec/support/*.rb')]
support.each{|helper| require helper }

Spec::Runner.configure do |config|
  config.include Spec::Helpers
  config.extend Spec::GitRepo
  config.extend Spec::Helpers::SemanticNames

  config.before(:all) do
    FakeWeb.allow_net_connect = false
    FakeFS.activate!
    ENV["CLOUD_URL"] = nil
    ENV["NO_SSH"] = "true"
  end

  config.before(:each) do
    FakeFS::FileSystem.clear
    EY.instance_eval{ @config = nil }
  end
end

Spec::Matchers.define :have_command_like do |regex|
  match do |command_list|
    @found = command_list.find{|c| c =~ regex }
    !!@found
  end

  failure_message_for_should do |command_list|
    "Didn't find a command matching #{regex} in commands:\n\n" + command_list.join("\n\n")
  end

  failure_message_for_should_not do |command_list|
    "Found unwanted command:\n\n#{@found}\n\n(matches regex #{regex})"
  end
end

EY.define_git_repo("default") do |git_dir|
  system("echo 'source :gemcutter' > Gemfile")
  system("git add Gemfile")
  system("git commit -m 'initial commit' >/dev/null 2>&1")
end

shared_examples_for "integration without an eyrc file" do
  use_git_repo('default')

  before(:all) do
    FakeFS.deactivate!
    ENV['EYRC'] = "/tmp/eyrc"
    FakeWeb.allow_net_connect = true
    ENV['CLOUD_URL'] = EY.fake_awsm
  end

  after(:all) do
    ENV.delete('CLOUD_URL')
    ENV.delete('EYRC')
    FakeFS.activate!
    FakeWeb.allow_net_connect = false
  end
end

# Use this in conjunction with the 'ey' helper method
shared_examples_for "integration" do
  given "integration without an eyrc file"

  before(:all) do
    token = { ENV['CLOUD_URL'] => {
        "api_token" => "f81a1706ddaeb148cfb6235ddecfc1cf"} }
    File.open(ENV['EYRC'], "w"){|f| YAML.dump(token, f) }
  end
end

shared_examples_for "it has an api" do
  before(:all) do
    @api = EY::API.new('asdf')
  end
end


# Shared behavior for things that take an environment name
shared_examples_for "it takes an environment name" do

  def run_ey(command_options, ey_options)
    if respond_to?(:extra_ey_options)   # needed for ssh tests
      ey_options.merge!(extra_ey_options)
    end

    ey(command_to_run(command_options), ey_options)
  end

  def _verify_ran(scenario)
    if respond_to?(:verify_ran)
      verify_ran(scenario)
    else
      pending "Need to implement verify_ran"
    end
  end

  def make_scenario(hash)
    # since nil will silently turn to empty string when interpolated,
    # and there's a lot of string matching involved in integration
    # testing, it would be nice to have early notification of typos.
    scenario = Hash.new { |h,k| raise "Tried to get key #{k.inspect}, but it's missing!" }
    scenario.merge!(hash)
  end

  it "complains when you specify a nonexistent environment" do
    api_scenario "one app, one environment"
    run_ey({:env => 'typo-happens-here'}, {:expect_failure => true})
    @err.should match(/no environment named 'typo-happens-here'/i)
  end

  context "given a piece of the environment name" do
    before(:all) do
      api_scenario "one app, many similarly-named environments"
    end
    it "complains when the substring is ambiguous" do
      run_ey({:env => 'staging'}, {:expect_failure => true})
      @err.should match(/'staging' is ambiguous/)
    end

    it "works when the substring is unambiguous" do
      api_scenario "one app, many similarly-named environments"
      run_ey({:env => 'prod'}, {:debug => true})
      _verify_ran(make_scenario({
            :environment  => 'railsapp_production',
            :application  => 'rails232app',
            :master_ip    => '174.129.198.124',
            :ssh_username => 'turkey',
          }))
    end
  end

  it "complains when it can't guess the environment and its name isn't specified" do
    api_scenario "one app, one environment, not linked"
    run_ey({:env => nil}, {:expect_failure => true})
    @err.should =~ /single environment/i
  end

end
