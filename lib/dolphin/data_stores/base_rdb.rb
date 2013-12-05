module Dolphin
  module DataStore
    class BaseRdb

      def initialize(config)
        @adapter = config[:adapter]
        @host = config[:host]
        @user = config[:user]
        @password = config[:password]
        @database = config[:database]

        # Set timezone to UTC
        Sequel.default_timezone = :utc
      end

      def current_database
        Sequel.connect(connect_path)
      end

      def closed?
        @connection.nil?
      end

      ORM = Dolphin::Models::Rdb::Orm

      def get_notification(id)
        n = Dolphin::Models::Rdb::Notification.new(ORM::Notification)
        n.get(id)
      end

      def put_event(event)
        e = Dolphin::Models::Rdb::Event.new(ORM::Event)
        e.put(event)
      end

      def get_event(params)
        e = Dolphin::Models::Rdb::Event.new(ORM::Event)
        e.get(params)
      end

      def put_notification(id, methods)
        n = Dolphin::Models::Rdb::Notification.new(ORM::Notification)
        n.put(id, methods)
      end

      def delete_notification(notification)
        n = Dolphin::Models::Rdb::Notification.new(ORM::Notification)
        n.delete(notification)
      end

      def get_host(id)
        h = Dolphin::Models::Rdb::Host.new(ORM::Host)
        h.get(id)
      end

      def get_item(hostid, item_key)
        i = Dolphin::Models::Rdb::Item.new(ORM::Item)
        i.get(hostid, item_key)
      end

      def get_history(params)
        h = Dolphin::Models::Rdb::History.new(ORM::History)
        h.get(params)
      end

      def connect_path
        "#{@adapter}://#{@host}/#{@database}?user=#{@user}&password=#{@password}"
      end

    end
  end
end
