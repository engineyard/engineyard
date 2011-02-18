require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
  spec.spec_opts = ["--color", "--format specdoc"]
end
task :test => :spec
task :default => :spec

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'rake/rdoctask'
require File.expand_path("../lib/engineyard", __FILE__)
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "engineyard #{EY::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.exclude('lib/vendor/**/*.rb')
end

def bump
  require 'engineyard'
  version_file = "module EY\n  VERSION = '_VERSION_GOES_HERE_'\nend\n"

  new_version = if EY::VERSION =~ /\.pre$/
                  EY::VERSION.gsub(/\.pre$/, '')
                else
                  digits = EY::VERSION.scan(/(\d+)/).map { |x| x.first.to_i }
                  digits[-1] += 1
                  digits.join('.') + ".pre"
                end

  puts "New version is #{new_version}"
  File.open('lib/engineyard/version.rb', 'w') do |f|
    f.write version_file.gsub(/_VERSION_GOES_HERE_/, new_version)
  end
  new_version
end

def bump_serverside_adapter
  specs = Gem::SpecFetcher.fetcher.fetch(Gem::Dependency.new("engineyard-serverside-adapter"))
  versions = specs.map {|spec,| spec.version}.sort
  latest_adapter_version = versions.last.to_s

  File.open('engineyard.gemspec', 'r') do |read_gemfile|
    File.unlink('engineyard.gemspec')
    File.open('engineyard.gemspec', 'w') do |write_gemfile|
      read_gemfile.each_line do |line|
        if line =~ /s.add_dependency\('engineyard-serverside-adapter',/
          write_gemfile.write("  s.add_dependency(\'engineyard-serverside-adapter\', \'=#{latest_adapter_version}\')   # This line maintained by rake; edits may be stomped on\n")
        else
          write_gemfile.write(line)
        end
      end
    end
  end
end

desc "Bump version of this gem"
task :bump do
  ver = bump
  puts "New version is #{ver}"
end

def run_commands(*cmds)
  cmds.flatten.each do |c|
    system(c) or raise "Command "#{c}" failed to execute; aborting!"
  end
end

desc "Release gem"
task :release do
  # Make sure we work with the latest version of serverside(-adapter)
  bump_serverside_adapter
  run_commands(
    "bundle install",
    "rake spec") # can't invoke directly; new gems won't get picked up

  new_version = bump

  run_commands(
    "git add Gemfile lib/engineyard/version.rb",
    "git commit -m 'Bump versions for release #{new_version}'",
    "gem build engineyard.gemspec")

  load 'lib/engineyard/version.rb'
  bump

  run_commands(
    "git add lib/engineyard/version.rb",
    "git commit -m 'Add .pre for next release'",
    "git tag v#{new_version} HEAD^")

  puts '********************************************************************************'
  puts
  puts "Don't forget to `ey-gem rubygems engineyard-#{new_version}.gem` and `git push origin master v#{new_version}`!"
  puts
  puts '********************************************************************************'
end
