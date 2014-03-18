source 'https://rubygems.org'

gemspec

group :mysql do
  gem 'sequel', '4.4.0'
  gem 'mysql2', '0.3.13'
end

group :cassandra do
  gem 'cassandra', '0.23.0'
end

group :development, :test do
  gem 'rspec', '2.13.0'
  gem 'pry'
  gem 'rb-readline'
end

gem 'reel', :git => 'https://github.com/celluloid/reel.git', :ref => '6952a824fe1ce206ce74d242327adf1bc7ce5cf3'
gem 'reel-rack', :git => 'https://github.com/axsh/reel-rack.git', :branch => 'fix-request-header', :ref => '88f2dd5a4852df573bb4f8360a0f68a6c6083a0c'
