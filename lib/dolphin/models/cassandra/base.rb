# -*- coding: utf-8 -*-
module Dolphin
  module Models::Cassandra
    class Base
      attr_accessor :db
      def initialize(connection)
        @db = connection
      end
    end
  end
end