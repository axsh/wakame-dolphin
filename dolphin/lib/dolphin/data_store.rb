module Dolphin
  module DataStore
    include Dolphin::Util

    def db
      @connection ||= Dolphin::DataStore.create(Dolphin.settings['database']['adapter'].to_sym, {
        :class => self
      }).connect

      if @connection.nil?
        raise 'Connection to database failed'
      else
        @connection
      end
    end

    def hosts
      Dolphin.settings['database']['hosts']
    end

    def self.create(adapter, options)

      config = {
        :hosts => Dolphin.settings['database']['hosts'],
        :port => Dolphin.settings['database']['port'],
        :max_retry_count => Dolphin.settings['database']['max_retry_count'].to_i,
        :retry_interval => Dolphin.settings['database']['retry_interval'].to_i
      }

      case adapter
        when :cassandra
          # TODO: more better code
          column_family = options[:class].class.name.split('::')[2].downcase + 's'
          klass = Dolphin::DataStore::Cassandra
          config.merge!({
            :keyspace => Dolphin::DataStore::Cassandra::KEYSPACE,
            :cf => column_family
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
