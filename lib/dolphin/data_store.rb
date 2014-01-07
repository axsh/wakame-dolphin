module Dolphin
  module DataStore
    include Dolphin::Util

    DATABASE = 'dolphin'.freeze

    def self.current_store
      if Dolphin.settings['database'] && !Dolphin.settings['database']['adapter'].blank?
        create(Dolphin.settings['database']['adapter'].to_sym)
      else
        raise 'Unknown database'
      end
    end

    def self.create(adapter)
      config = {}
      database = Dolphin.settings['database']
      case adapter
        when :cassandra
          klass = Dolphin::DataStore::Cassandra
          config.merge!({
            :keyspace => DATABASE,
            :hosts => database['hosts'],
            :port => database['port'],
            :max_retry_count => Util.to_i(database['max_retry_count']),
            :retry_interval => Util.to_i(database['retry_interval']),
            :thrift_retries => Util.to_i(database['thrift_retries']),
            :thrift_timeout => Util.to_i(database['thrift_timeout']),
            :thrift_connect_timeout => Util.to_i(database['thrift_connect_timeout']),
          })

        when :mysql
          klass = Dolphin::DataStore::Mysql
          config.merge!({
            :adapter => 'mysql2',
            :database => DATABASE,
            :host => database['host'],
            :port => database['port'],
            :user => database['user'],
            :password => database['password'],
          })
        when :mock
          klass = Dolphin::DataStore::Mock
        else
          raise NotImplementedError
      end
      klass.new(config)
    end

    class ConncetionBase
      include Dolphin::Util

      def connect
        raise NotImplementedError
      end

      def path
        raise NotImplementedError
      end
    end
  end
end
