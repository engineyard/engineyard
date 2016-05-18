#!/usr/bin/env rake
require "bundler/gem_tasks"

namespace :spec do
  task :mocked do
    sh "bundle exec rspec spec/"
  end
end

task :spec => ["spec:mocked"]

task default: "spec:mocked"
