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

    def self.create(adapter, settings={})
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
            :database => settings[:database].blank? ? DATABASE : settings[:database],
            :host => settings[:host].blank? ? Dolphin.settings['database']['host'] : settings[:host],
            :port => settings[:port].blank? ? Dolphin.settings['database']['port'] : settings[:port],
            :user => settings[:user].blank? ? Dolphin.settings['database']['user'] : settings[:user],
            :password => settings[:password].blank? ? Dolphin.settings['database']['password'] : settings[:password],
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
