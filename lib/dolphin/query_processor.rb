# -*- coding: utf-8 -*-

require 'celluloid'

module Dolphin
  class QueryProcessor
    include Celluloid
    include Dolphin::Util

    def get_notification(id)
      logger :info, "Get notification #{id}"
      send('get_notification', id)
    end

    def put_event(event)
      logger :info, "Put event #{event}"
      send('put_event', event)
    end

    def get_event(params)
      send('get_event', params)
    end

    def put_notification(notification)
      logger :info, notification
      notification_id = notification[:id]
      methods = notification[:methods]
      send('put_notification', notification_id, methods)
    end

    def delete_notification(notification)
      logger :info, notification
      notification_id = notification[:id]
      send('delete_notification', notification_id)
    end

    private
    def send(action, *args)
      begin
        ds = DataStore.current_store
        ds.connect
        ds.__send__(action, *args)
      rescue => e
        logger :error, e.backtrace
        logger :error, e
        false
      end
    end
  end
end