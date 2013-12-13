# -*- coding: utf-8 -*-
module Dolphin
  module Models::Cassandra
    class Base
      def initialize(connection)
        @db = connection
      end

      def db
        raise 'Connection refused' if @db.nil?
        @db
      end
    end
  end
end
