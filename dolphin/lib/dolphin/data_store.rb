module Dolphin
  module DataStore
    include Dolphin::Util

    def self.current_store
      create(Dolphin.settings['database']['adapter'].to_sym)
    end

    def hosts
      Dolphin.settings['database']['hosts']
    end

    def self.create(adapter)

      config = {
        :hosts => Dolphin.settings['database']['hosts'],
        :port => Dolphin.settings['database']['port'],
        :max_retry_count => Dolphin.settings['database']['max_retry_count'].to_i,
        :retry_interval => Dolphin.settings['database']['retry_interval'].to_i
      }

      case adapter
        when :cassandra
          klass = Dolphin::DataStore::Cassandra
          config.merge!({
            :keyspace => Dolphin::DataStore::Cassandra::KEYSPACE,
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
