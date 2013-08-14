source "https://rubygems.org"

gemspec

gem 'engineyard-cloud-client', :path => "../engineyard-cloud-client"
gem 'pry'

group 'engineyard-cloud-client-test' do
  gem 'dm-core', '~>1.2.0'
  gem 'dm-migrations'
  gem 'dm-aggregates'
  gem 'dm-timestamps'
  gem 'dm-sqlite-adapter'
  gem 'ey_resolver', '~>0.2.1'
  gem 'rabl'
  gem 'activesupport', '< 4.0.0'
end

group :coverage do
  gem 'simplecov', :require => false
end
