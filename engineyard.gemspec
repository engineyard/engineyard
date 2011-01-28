# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'bundler'
require 'engineyard'

Gem::Specification.new do |s|
  s.name = "engineyard"
  s.version = EY::VERSION
  s.platform = Gem::Platform::RUBY
  s.author = "EY Cloud Team"
  s.email = "cloud@engineyard.com"
  s.homepage = "http://github.com/engineyard/engineyard"
  s.summary = "Command-line deployment for the Engine Yard cloud"
  s.description = "This gem allows you to deploy your rails application to the Engine Yard cloud directly from the command line."
  s.post_install_message = File.read("PostInstall.txt")

  s.files = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.rdoc)
  s.executables = ["ey"]
  s.default_executable = "ey"
  s.require_path = 'lib'

  s.rubygems_version = %q{1.3.6}
  s.test_files = Dir.glob("spec/**/*")

  s.add_bundler_dependencies
end
