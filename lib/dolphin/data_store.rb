module Dolphin
  module DataStore
    include Dolphin::Util

    DATABASE = 'dolphin'.freeze

    def self.current_store
      create(Dolphin.settings['database']['adapter'].to_sym)
    end

    def hosts
      Dolphin.settings['database']['hosts']
    end

    def self.create(adapter)
      config = {}
      case adapter
        when :cassandra
          klass = Dolphin::DataStore::Cassandra
          config.merge!({
            :keyspace => DATABASE,
            :hosts => Dolphin.settings['database']['hosts'],
            :port => Dolphin.settings['database']['port'],
            :max_retry_count => Dolphin.settings['database']['max_retry_count'].to_i,
            :retry_interval => Dolphin.settings['database']['retry_interval'].to_i
          })
        when :mysql
          klass = Dolphin::DataStore::Mysql
          config.merge!({
            :adapter => 'mysql2',
            :database => DATABASE,
            :host => Dolphin.settings['database']['host'],
            :port => Dolphin.settings['database']['port'],
            :user => Dolphin.settings['database']['user'],
            :password => Dolphin.settings['database']['password'],
          })
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
