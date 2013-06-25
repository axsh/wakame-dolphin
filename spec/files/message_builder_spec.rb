# -*- coding: utf-8 -*-

require 'spec_helper'

describe Dolphin::TemplateBuilder do
  describe ".build" do
    it 'expect to build template' do
      tb = Dolphin::TemplateBuilder.new

      template_str = 'hello <%= @foo %>'
      bind_params = {:foo => 'world'}
      expect(tb.build(template_str, bind_params)).to eql 'hello world'
    end
  end
end