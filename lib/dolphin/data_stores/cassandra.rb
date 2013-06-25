# -*- coding: utf-8 -*-

require 'cassandra/1.1'

module Thrift
  class FramedTransport < BaseTransport
    def write(buf,sz=nil)
      if !['US-ASCII', 'ASCII-8BIT'].include?(buf.encoding.to_s)
        buf = buf.unpack("a*").first
      end
      return @transport.write(buf) unless @write

      @wbuf << (sz ? buf[0...sz] : buf)
    end
  end
end

module Dolphin
  module DataStore
    class Cassandra
      include Dolphin::Util

      class UnAvailableNodeException < Exception; end

      PATH_SEPARATOR = ':'.freeze

      def initialize(config)
        @keyspace = config[:keyspace]
        raise "database hosts is blank" if config[:hosts].blank?
        @hosts = config[:hosts].split(',')
        @port = config[:port]
        @max_retry_count = config[:max_retry_count] || 3
        @retry_interval = config[:retry_interval] || 3
        @retry_count = 0
      end

      def connect
        begin
          if @connection.nil?
            @connection = ::Cassandra.new(@keyspace, seeds)

            # test connecting..
            @connection.ring
            return @connection
          end
        rescue ThriftClient::NoServersAvailable => e
          logger :error, e
          @connection = nil
          if @retry_count < @max_retry_count
            @retry_count += 1
            logger :error, "retry connection..#{@retry_count}"
            sleep @retry_interval
            retry
          end
        rescue UnAvailableNodeException => e
          logger :error, e
        rescue CassandraThrift::InvalidRequestException => e
          logger :error, e
        end
        @connection
      end

      def closed?
        @connection.nil?
      end

      def get_notification(id)
        n = Dolphin::Models::Cassandra::Notification.new(@connection)
        n.get(id)
      end

      def put_event(event)
        e = Dolphin::Models::Cassandra::Event.new(@connection)
        e.put(event)
      end

      def get_event(params)
        e = Dolphin::Models::Cassandra::Event.new(@connection)
        e.get(params)
      end

      def put_notification(id, methods)
        n = Dolphin::Models::Cassandra::Notification.new(@connection)
        n.put(id, methods)
      end

      def delete_notification(notification)
        n = Dolphin::Models::Cassandra::Notification.new(@connection)
        n.delete(notification)
      end

      private
      def seeds
        @hosts.collect{|host| "#{host}:#{@port}"}
      end
    end
  end
end