require 'date'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = %w[--color]
  t.pattern = 'spec/**/*_spec.rb'
end

task :coverage => [:coverage_env, :spec]

task :coverage_env do
  ENV['COVERAGE'] = '1'
end

task :test => :spec
task :default => :spec

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'rdoc/task'
require 'engineyard/version'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "engineyard #{EY::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

def remove_pre
  require 'engineyard/version'
  Gem::Version.create(EY::VERSION).release
end

def next_pre(version)
  digits = version.to_s.scan(/(\d+)/).map { |x| x.first.to_i }
  digits[-1] += 1
  digits.join('.') + ".pre"
end

def version_file
  Pathname.new('lib/engineyard/version.rb')
end

def write_version(new_version)
  with_version_contents do |contents|
    puts "engineyard (#{new_version})"

    if contents =~ /VERSION = '[^']+'/
      contents.sub(/VERSION = '[^']+'/,
                   "VERSION = '#{new_version}'")
    else
      raise "Problem writing version. Please check #{version_file}"
    end
  end
end

def write_serverside_version(serverside_version)
  with_version_contents do |contents|
    puts "engineyard-serverside (#{serverside_version})"

    words = "ENGINEYARD_SERVERSIDE_VERSION = ENV['ENGINEYARD_SERVERSIDE_VERSION'] ||"
    if contents =~ /#{Regexp.escape(words)} '[^']+'/
      contents.sub(/#{Regexp.escape(words)} '[^']+'/,
                   "#{words} '#{serverside_version}'")
    else
      raise "Problem writing serverside version. Please check #{version_file}"
    end
  end
end

def with_version_contents
  contents = version_file.read
  version_file.unlink
  version_file.open('w') do |f|
    f.write yield(contents)
  end
end

def release_changelog(version)
  clog = Pathname.new('ChangeLog.md')
  new_clog = clog.read.sub(/^## NEXT$/, <<-SUB.chomp)
## NEXT

  *

## v#{version} (#{Date.today})
  SUB
  clog.open('w') { |f| f.puts new_clog }
end

def update_serverside
  specs = Gem::SpecFetcher.fetcher.fetch(Gem::Dependency.new("engineyard-serverside"))
  latest_serverside_version = specs.map {|spec,| spec.version}.sort.last.to_s
  write_serverside_version(latest_serverside_version)
end

def update_serverside_adapter
  gem_name = "engineyard-serverside-adapter"
  specs = Gem::SpecFetcher.fetcher.fetch(Gem::Dependency.new(gem_name))
  latest_adapter_version = specs.map {|spec,| spec.version}.sort.last.to_s
  version_changed = false

  gemspec_file = Pathname.new('engineyard.gemspec')

  gemspec_file.open('r') do |read_gemfile|
    gemspec_file.unlink
    gemspec_file.open('w') do |write_gemfile|
      read_gemfile.each_line do |line|
        if line =~ /s.add_dependency\('#{gem_name}', '=([^']+)'/
          version_changed = ($1 != latest_adapter_version)
          puts "#{gem_name} (#{latest_adapter_version})"
          write_gemfile.write("  s.add_dependency(\'#{gem_name}\', \'=#{latest_adapter_version}\')   # This line maintained by rake; edits may be stomped on\n")
        else
          write_gemfile.write(line)
        end
      end
    end
  end

  # re-bundle if the version changed
  if version_changed
    puts "Bundled gem version changed. Running bundle install..."
    Bundler.with_clean_env do
      system('bundle install')
    end
  end
end

namespace :update do
  desc "Update to latest version of engineyard-serverside"
  task "serverside" do
    update_serverside
  end

  desc "Update to latest version of engineyard-serverside-adapter"
  task "adapter" do
    update_serverside_adapter
  end
end

desc "Update to latest serverside and adapter versions"
task :update => ['update:serverside', 'update:adapter']

def run_commands(*cmds)
  cmds.flatten.each do |c|
    system(c) or raise "Command #{c.inspect} failed to execute; aborting!"
  end
end

desc "Release gem"
task :release do
  run_commands(
    "bundle install",
    "rake spec") # can't invoke directly; new gems won't get picked up

  new_version = remove_pre
  write_version new_version
  release_changelog(new_version)

  run_commands(
    "git add Gemfile ChangeLog.md lib/engineyard/version.rb engineyard.gemspec",
    "git commit -m 'Bump versions for release #{new_version}'",
    "gem build engineyard.gemspec")

  if system("gem spec engineyard-#{new_version}.gem | grep Syck")
    raise "Syck found in gemspec! Aborting!\nYou will need to revert the last commit yourself and build from a ruby without this Syck problem: 1.8 or a properly Psych linked 1.9."
  end

  write_version next_pre(new_version)

  run_commands(
    "git add lib/engineyard/version.rb",
    "git commit -m 'Add .pre for next release'",
    "git tag v#{new_version} HEAD^")

  puts <<-PUSHGEM
## To publish the gem: #########################################################

    gem push engineyard-#{new_version}.gem
    git push origin master v#{new_version}

## No public changes yet. ######################################################
  PUSHGEM
end
