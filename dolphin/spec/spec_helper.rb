# -*- coding: utf-8 -*-

require 'rubygems'
require 'rspec'
require File.join(File.expand_path('../../', __FILE__), 'lib/dolphin')


# TODO: Factory Girl
# TODO: Rack Test
# TODO: JSON Test
RSpec.configure do |c|
  c.filter_run_excluding :smtp => true
end
