# -*- coding: utf-8 -*-

require 'sequel'

module Dolphin
  module DataStore
    class Mysql < BaseRdb
      def connect
        @connection = current_database
        case @connection.adapter_scheme
        when :mysql, :mysql2
          Sequel::MySQL.default_charset = 'utf8'
          Sequel::MySQL.default_collate = 'utf8_general_ci'
          Sequel::MySQL.default_engine = ENV['MYSQL_DB_ENGINE'] || 'InnoDB'

          # this is the mysql adapter specific constants. won't work with mysql2.
          if @connection.adapter_scheme == :mysql
            # Disable TEXT to Sequel::SQL::Blob translation.
            # see the thread: MySQL text turning into blobs
            # http://groups.google.com/group/sequel-talk/browse_thread/thread/d0f4c85abe9b3227/9ceaf291f90111e6
            # lib/sequel/adapters/mysql.rb
            [249, 250, 251, 252].each { |v|
              Sequel::MySQL::MYSQL_TYPES.delete(v)
            }
          end
        end
        @connection
      end
    end
  end
end