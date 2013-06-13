# -*- coding: utf-8 -*-

require 'rubygems'
require 'rspec'
require File.join(File.expand_path('../../', __FILE__), 'lib/dolphin')

ENV['BUNDLE_GEMFILE'] ||= File.expand_path(File.dirname(__FILE__) + '/Gemfile')
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
Bundler.require :default if defined?(Bundler)

# TODO: Factory Girl
# TODO: Rack Test
# TODO: JSON Test
RSpec.configure do |c|
  c.filter_run_excluding :smtp => true
end
