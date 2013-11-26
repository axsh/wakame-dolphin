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
      module Dolphin::Helpers::Message
        module BrokenHelper
          def broken_message(str)
            str + nil
          end
        end
      end

      Dolphin::TemplateBuilder.module_eval do
        include Dolphin::Helpers::Message::BrokenHelper
      end

      class TestMessageBuilderMail < Dolphin::MessageBuilder::Mail
        private
        def template(template_id)
          header = "<%= @subject %>"
          body = "<%= broken_message('crash') %>"
          return [header,MESSAGE_BOUNDARY,body].join("\n")
        end
      end

      mb = TestMessageBuilderMail.new
      template = mb.build('broken_template', {
        'messages' => {
          'subject' => 'subject',
        }
      })

      expect(template).to be_nil
    end
  end
end
