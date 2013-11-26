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

    it 'expect to load external template' do
      message_type = 'test'

      expect(Dolphin.settings['template']).to be_true
      expect(Dolphin.settings['template']['template_path']).to be_true

      mb = Dolphin::MessageBuilder::Mail.new
      bind_params = {
        'messages' => {
          'subject' => 'subject',
          'body' => 'body'
        },
        "to" => "to@example.com",
        "cc" => "cc@example.com",
        "bcc" =>"bcc@example.com"
      }
      notification_object = mb.build(message_type, bind_params)

      expect(notification_object).not_to be_nil
      expect(notification_object).to be_kind_of Dolphin::NotificationObject
      expect(notification_object.subject).to eq bind_params['messages']['subject']
      expect(notification_object.body).to eq bind_params['messages']['body']
      expect(notification_object.to).to eq bind_params['to']
      expect(notification_object.cc).to eq bind_params['cc']
      expect(notification_object.bcc).to eq bind_params['bcc']
    end
  end
end
