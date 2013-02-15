source "https://rubygems.org"

gemspec

group :guard do
  gem 'guard', :require => false
  gem 'guard-rspec', :require => false
  gem 'rb-fsevent', '~> 0.9.1', :require => false
end

group 'engineyard-cloud-client-test' do
  gem 'dm-core', '~>1.2.0'
  gem 'dm-migrations'
  gem 'dm-aggregates'
  gem 'dm-timestamps'
  gem 'dm-sqlite-adapter'
  gem 'ey_resolver', '~>0.2.1'
  gem 'rabl'
end

group :coverage do
  gem 'simplecov', :require => false
end
