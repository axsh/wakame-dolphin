# -*- coding: utf-8 -*-

module Dolphin::Models
  module Rdb
    class Base
      attr_accessor :db
      def initialize(model_class)
        @db = model_class
      end
    end
  end
end