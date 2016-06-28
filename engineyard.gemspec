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
  s.post_install_message = File.read("PostInstall.txt")
  s.license = 'MIT'

  s.required_ruby_version = '>= 1.9.3'

  s.files = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.md)
  s.executables = ["ey"]
  s.default_executable = "ey"
  s.require_path = 'lib'

  s.test_files = Dir.glob("spec/**/*")

  s.add_dependency('highline', '~> 1.6.1')
  s.add_dependency('escape', '~> 0.0.4')
  s.add_dependency('engineyard-serverside-adapter', '~> 2.2')
  s.add_dependency('engineyard-cloud-client', '~> 2.1')
  s.add_dependency('net-ssh', '~>2.7')
  s.add_dependency('launchy', '~>2.1')
  s.add_dependency('ey-core', '~>3.1.4')

  s.add_development_dependency('rspec', '~> 2.0')
  s.add_development_dependency('rake', '~> 10.4')
  s.add_development_dependency('rdoc', '~> 4.2')
  s.add_development_dependency('fakeweb', '~> 1.3')
  s.add_development_dependency('fakeweb-matcher', '~> 1.2')
  s.add_development_dependency('sinatra', '~> 1.4')
  s.add_development_dependency('realweb', '~> 1.0.1')
  s.add_development_dependency('open4', '~> 1.0.1')
  s.add_development_dependency('multi_json', '~> 1.11')
  s.add_development_dependency('oj', '~> 2.14')

  s.add_development_dependency('dm-core', '~> 1.2')
  s.add_development_dependency('dm-migrations', '~> 1.2')
  s.add_development_dependency('dm-aggregates', '~> 1.2')
  s.add_development_dependency('dm-timestamps', '~> 1.2')
  s.add_development_dependency('dm-sqlite-adapter', '~> 1.2')
  s.add_development_dependency('addressable', '= 2.3.8')
  s.add_development_dependency('ey_resolver', '~> 0.2.1')
  s.add_development_dependency('rabl', '~> 0.11')
  s.add_development_dependency('activesupport', '< 4.0.0')
  s.add_development_dependency('simplecov', '~> 0.11')
end
