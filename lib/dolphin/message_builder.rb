# -*- coding: utf-8 -*-
require 'erubis'
require 'extlib/blank'

module Dolphin

  class TemplateBuilder

    include Dolphin::Helpers::Message::ZabbixHelper

    # Load plugable helpers
    if Dolphin.settings['template']
      Dir.glob(File.join(Dolphin.settings['template']['helper_module_path'], '*_helper.rb')).each {|f|
        require f
      }
    end

    Dolphin::Helpers::Message.constants.each {|c|
      include Dolphin::Helpers::Message.const_get(c)
    }

    def build(template_str, params)
      template = Erubis::Eruby.new(template_str)
      if params.is_a? Hash
        params.each {|key, val|
          instance_variable_set("@#{key}", val)
        }
      end
      template.result(binding)
    end
  end

  module MessageBuilder

    EXT = '.erb'.freeze

    class Base

      include Dolphin::Util

      def initialize
      end

      def build
        raise NotImplementedError
      end

      def build_message(str, params)
        begin
          template = TemplateBuilder.new
          template.build(str, params).encode("UTF-8")
        rescue => e
          logger :error, e
          logger :error, e.backtrace
          nil
        end
      end
    end

    class Mail < Base

      MESSAGE_BOUNDARY="----------------------------------------".freeze

      def build(template_id, params)
        message = ''

        if template_id.blank?
          template_id = 'default'
        end

        body_template = template(template_id)
        if body_template.nil?
          return nil
        end

        message = build_message(body_template, params['messages'])
        return nil  if message.nil?
        subject, body = message.split(MESSAGE_BOUNDARY)
        subject.strip! unless subject.nil?
        body.strip! unless body.nil?

        notification = NotificationObject.new
        notification.subject = subject
        notification.from = Dolphin.settings['mail']['from']
        notification.to = params["to"]
        notification.cc ||= params["cc"]
        notification.bcc ||= params["bcc"]
        notification.body = body
        notification
      end

      private
      def template(template_id)
        load_target_templates = []

        if Dolphin.settings['template']
          load_target_templates << File.join(Dolphin.settings['template']['template_path'], 'email')
        end

        load_target_templates << template_path
        load_target_templates.each {|path|
          file_path = File.join(path, template_file(template_id))
          if File.exists? file_path
            return File.read(file_path, :encoding => Encoding::UTF_8)
          else
            logger :warn, "File not found #{file_path}"
            return nil
          end
        }
      end

      def template_file(template_id)
        template_id + EXT
      end

      def template_path
        File.join(Dolphin.templates_path, '/email')
      end
    end
  end
end
