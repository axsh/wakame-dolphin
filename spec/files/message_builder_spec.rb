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

    it "expect to nil template when broken helper" do
      mb = Dolphin::MessageBuilder::Mail.new
      message_type = 'broken_template'
      template = mb.build(message_type, {
        'messages' => {
          'subject' => 'subject',
        }
      })

      expect(template).to be_nil
    end
  end
end
