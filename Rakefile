require 'jeweler'
require 'bundler'
require 'lib/engineyard'

Jeweler::Tasks.new do |gem|
  gem.name = "engineyard"
  gem.summary = %Q{Command-line deployment for the Engine Yard cloud}
  gem.description = %Q{This gem allows you to deploy your rails application to the Engine Yard cloud directly from the command line.}
  gem.email = "cloud@engineyard.com"
  gem.homepage = "http://engineyard.com"
  gem.author = "EY Cloud Team"
  gem.version = EY::VERSION
  gem.files = FileList["README.rdoc", "LICENSE", "{bin,lib}/**/*"]

  bundle = Bundler::Definition.from_gemfile('Gemfile')
  bundle.dependencies.each do |dep|
    if dep.groups.include?(:runtime)
      gem.add_dependency(dep.name, dep.requirement.to_s)
    elsif dep.groups.include?(:development)
      gem.add_development_dependency(dep.name, dep.requirement.to_s)
    end
  end
end
Jeweler::GemcutterTasks.new

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

task :spec => :check_dependencies
task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "engineyard #{EY::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.exclude('lib/vendor/**/*.rb')
end
