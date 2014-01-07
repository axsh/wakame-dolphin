# -*- coding: utf-8 -*-

require 'celluloid'

module Dolphin
  module Util
    include Celluloid::Logger

    class << self
      def to_i(value)
        value.nil? ? nil : value.to_i
      end
    end

    def logger(type, message)
      message = {
        :message => message,
        :classname => self.class.name,
        :thread_id => Thread.current.object_id
      }
      Celluloid.logger.__send__(type, message)
    end
  end
end
