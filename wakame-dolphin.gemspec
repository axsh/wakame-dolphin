# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'dolphin/version'
Gem::Specification.new do |spec|
  spec.name        = 'wakame-dolphin'
  spec.version     = Dolphin::VERSION
  spec.platform    = Gem::Platform::RUBY
  spec.summary     = 'notification service'
  spec.description = 'notification service'
  spec.licenses    = ['LGPL 3.0']

  spec.authors     = ['axsh Ltd.']
  spec.email       = ['dev@axsh.net']
  spec.homepage    = 'https://github.com/axsh/wakame-dolphin'

  spec.required_ruby_version     = '>= 2.0.0'
  spec.required_rubygems_version = '>= 1.3.6'

  spec.files        = `git ls-files`.split($/)
  spec.executables  = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files   = spec.files.grep(%r{^(tests|spec)/})
  spec.require_path = ['lib']

  spec.add_runtime_dependency 'reel-rack'
  spec.add_runtime_dependency 'actionmailer', '= 3.2.12'
  spec.add_runtime_dependency 'ltsv', '= 0.1.0'
  spec.add_runtime_dependency 'extlib', '~> 0.9.16'
  spec.add_runtime_dependency 'multi_json', '1.6.1'
  spec.add_runtime_dependency 'rake', '= 10.0.3'
  spec.add_runtime_dependency 'parseconfig', '= 1.0.2'
  spec.add_runtime_dependency 'erubis', '= 2.7.0'
  spec.add_runtime_dependency 'mail-iso-2022-jp', '= 2.0.1'
  spec.add_runtime_dependency 'simple_uuid', '= 0.4.0'
  spec.add_runtime_dependency 'sinatra', '~> 1.4.0'
  spec.add_runtime_dependency 'sinatra-contrib', '~> 1.4.0'

  # stick gem versions for reel.
  spec.add_runtime_dependency 'celluloid', '~> 0.15.0'
  spec.add_runtime_dependency 'celluloid-io', '~> 0.15.0'
  spec.add_runtime_dependency 'nio4r', '~> 0.5.0'
  spec.add_runtime_dependency 'reel'
  spec.add_runtime_dependency 'http', '~> 0.5.0'
  spec.add_runtime_dependency 'http_parser.rb', '~> 0.6.0.beta.2'
  spec.add_runtime_dependency 'websocket_parser', '~> 0.1.4'
end
