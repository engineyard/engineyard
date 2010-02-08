require 'jeweler'
require 'bundler'
require 'lib/engineyard'

Jeweler::Tasks.new do |gem|
  gem.name = "engineyard"
  gem.summary = %Q{Command-line deployment for the Engine Yard cloud}
  gem.description = %Q{This gem allows you to deploy your rails application to the Engine Yard cloud directly from the command line.}
  gem.email = "awsmdev@engineyard.com"
  gem.homepage = "http://github.com/engineyard/engineyard"
  gem.authors = ["Andy Delcambre", "Andre Arko", "Ezra Zygmuntowicz"]
  gem.version = EY::VERSION

  bundle = Bundler::Definition.from_gemfile('Gemfile')
  bundle.dependencies.each do |dep|
    next unless dep.groups.include?(:runtime)
    gem.add_dependency(dep.name, dep.version_requirements.to_s)
  end
end
Jeweler::GemcutterTasks.new

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "engineyard #{EY::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
