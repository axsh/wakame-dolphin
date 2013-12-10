source 'https://rubygems.org'

gemspec

group :mysql do
  gem 'sequel', '4.4.0'
  gem 'mysql2', '0.3.13'
end

group :cassandra do
  gem 'cassandra', '0.17.0'
end

group :development, :test do
  gem 'rspec', '2.13.0'
  gem 'pry'
  gem 'rb-readline'
end

gem 'reel-rack', :git => 'https://github.com/axsh/reel-rack.git', :branch => 'fix-request-header'
