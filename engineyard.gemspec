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

  s.files = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.rdoc)
  s.executables = ["ey"]
  s.default_executable = "ey"
  s.require_path = 'lib'

  s.rubygems_version = %q{1.3.6}
  s.test_files = Dir.glob("spec/**/*")

  s.add_dependency('rest-client', '~>1.6.0')
  s.add_dependency('highline', '~>1.6.1')
  s.add_dependency('escape', '~>0.0.4')
  s.add_dependency('engineyard-serverside-adapter', '=2.0.4')   # This line maintained by rake; edits may be stomped on
  s.add_dependency('engineyard-cloud-client', '~>1.0.7')
  s.add_dependency('net-ssh')
  s.add_dependency('launchy')

  s.add_development_dependency('rspec', '~>2.0')
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('fakeweb')
  s.add_development_dependency('fakeweb-matcher')
  s.add_development_dependency('sinatra')
  s.add_development_dependency('realweb', '~>1.0.1')
  s.add_development_dependency('open4', '~>1.0.1')
  s.add_development_dependency('hashie')
  s.add_development_dependency('gitable')
  s.add_development_dependency('multi_json', '~> 1.5')
end
