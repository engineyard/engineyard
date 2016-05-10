# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'engineyard/version'

Gem::Specification.new do |s|
  s.name = "engineyard"
  s.version = EY::VERSION
  s.platform = Gem::Platform::RUBY
  s.author = "Engine Yard Cloud Team"
  s.email = "cloud@engineyard.com"
  s.homepage = "http://github.com/engineyard/engineyard"
  s.summary = "Command-line deployment for the Engine Yard cloud"
  s.description = "This gem allows you to deploy your rails application to the Engine Yard cloud directly from the command line."
  s.license = 'MIT'

  s.required_ruby_version = '>= 2.0'

  s.files = Dir.glob("{bin/**/*") + %w(LICENSE README.md)
  s.executables = ["ey"]
  s.default_executable = "ey"

  s.add_dependency "ey-core", "~> 3.1"
end
