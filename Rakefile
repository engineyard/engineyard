require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
  spec.spec_opts = ["--color", "--format specdoc"]
end
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

desc "Bump version of this gem"
task :bump do
  ver = bump
  puts "New version is #{ver}"
end

desc "Release gem"
task :release do
  new_version = bump

  system("git add lib/engineyard/version.rb")
  system("git commit -m 'Bump version for release #{new_version}'")
  system("git tag v#{new_version}")

  system("gem build engineyard.gemspec")

  load 'lib/engineyard/version.rb'
  bump
  system("git add lib/engineyard/version.rb")
  system("git commit -m 'Add .pre for next release'")

  puts '********************************************************************************'
  puts
  puts "Don't forget to `gem push` and `git push --tags`!"
  puts
  puts '********************************************************************************'
end
