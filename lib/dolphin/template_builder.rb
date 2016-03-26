# -*- coding: utf-8 -*-
require 'erubis'

module Dolphin
  class TemplateBuilder

    include Dolphin::Helpers::Message::ZabbixHelper
    include Dolphin::Util

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

      ### Build & Load Plugin
      result = nil
      100.times {|i|
        logger :info, '### loop times : ' + i.to_s
        begin
          template = Erubis::Eruby.new(template_str)
          if params.is_a? Hash
            params.each {|key, val|
              instance_variable_set("@#{key}", val)
            }
          end
          result = template.result(binding)
          break
        rescue NameError => e
          logger :info, e
          plugin_group_name = 'plugin_' + e.name.to_s.downcase
          plugin_file_name = e.name.to_s.downcase + '_plugin.rb'

          if Dolphin.settings[plugin_group_name] && Dolphin.settings[plugin_group_name].has_key?('plugin_module_path')
            Dir.glob(File.join(File.expand_path(Dolphin.settings[plugin_group_name]['plugin_module_path']), plugin_file_name)).each {|f|
              require f
              logger :info, '### load plugin module : ' + f.to_s
            }
          end
          next
        rescue => e
          logger :error, e
          logger :error, e.backtrace
          break
        end
      }
      result
    end

  end
end
