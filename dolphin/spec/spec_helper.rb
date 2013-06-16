# -*- coding: utf-8 -*-

require 'rubygems'
require 'rspec'
require File.join(File.expand_path('../../', __FILE__), 'lib/dolphin')

# Setup Bundler
ENV['BUNDLE_GEMFILE'] ||= File.expand_path(File.dirname(__FILE__) + '/Gemfile')
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
Bundler.require :default if defined?(Bundler)

# Load helper files
Dir.glob('./spec/helpers/*_helper.rb').each {|f| require File.expand_path(f) }

RSpec.configure do |c|
  c.include WebRequestHelper
end
