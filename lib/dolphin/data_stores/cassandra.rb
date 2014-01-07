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

        # thrift_client_options
        # quoted from: https://github.com/twitter/thrift_client/blob/master/lib/thrift_client.rb
        # <tt>:retries</tt>:: How many times to retry a request. Defaults to 0.
        # <tt>:timeout</tt>:: Specify the default timeout in seconds. Defaults to <tt>1</tt>.
        # <tt>:connect_timeout</tt>:: Specify the connection timeout in seconds. Defaults to <tt>0.1</tt>.
        @thrift_retries = config[:thrift_retries] || 3
        @thrift_timeout = config[:thrift_timeout] || 3
        @thrift_connect_timeout = config[:thrift_connect_timeout] || 1
      end

      def connect
        begin
          if @connection.nil?

            cassandra_options = {
              :thrift_client_options => {
                :retries => @thrift_retries,
                :timeout => @thrift_timeout,
                :connect_timeout => @thrift_connect_timeout
              }
            }

            @connection = ::Cassandra.new(@keyspace, seeds, cassandra_options)

            # test connecting..
            @connection.ring
            return @connection
          end
        rescue ThriftClient::NoServersAvailable => e
          @connection = nil
          if @retry_count < @max_retry_count
            @retry_count += 1
            logger :info, "retry connection..#{@retry_count}"
            sleep @retry_interval
            retry
          else
            logger :error, e
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
