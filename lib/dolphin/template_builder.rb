# -*- coding: utf-8 -*-
require 'erubis'

module Dolphin
  class TemplateBuilder

    include Dolphin::Helpers::Message::ZabbixHelper

    # Load plugable helpers
    if Dolphin.settings['template'] && Dolphin.settings['template'].has_key?('helper_module_path')
      Dir.glob(File.join(File.expand_path(Dolphin.settings['template']['helper_module_path']), '*_helper.rb')).each {|f|
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
end
