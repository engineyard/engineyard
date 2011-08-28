# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{demo}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Shai Rosenfeld}]
  s.date = %q{2011-08-28}
  s.description = %q{extension to ey gem}
  s.email = [%q{srosenfeld@engineyard.com}]
  s.executables = []
  s.extra_rdoc_files = [ %q{Manifest.txt},]
  s.files = [%q{.autotest}, %q{Manifest.txt}, %q{lib/demo.rb}, %q{test/test_demo.rb}]
  s.homepage = %q{http://engineyard.com}
  s.rdoc_options = [%q{--main}]
  s.require_paths = [%q{lib}]
  s.rubyforge_project = %q{demo}
  s.rubygems_version = %q{1.8.6}
  s.summary = %q{extension to ey gem}
  s.test_files = [%q{test/test_demo.rb}]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, ["~> 2.12"])
    else
      s.add_dependency(%q<hoe>, ["~> 2.12"])
    end
  else
    s.add_dependency(%q<hoe>, ["~> 2.12"])
  end
end
