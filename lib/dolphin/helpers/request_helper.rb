# -*- coding: utf-8 -*-
require 'multi_json'
require 'extlib/blank'

module Dolphin
  module Helpers
    module RequestHelper

      def required(name)
        case name
          when 'notification_id'
            raise 'Not found X-Notification-Id' if @notification_id.nil?
        end
      end

      def parse_time(time)
        return nil if time.blank? || !time.is_a?(String)
        Time.parse(URI.decode(time)).to_time
      end
    end
  end
end
