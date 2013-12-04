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

    def get_host(id)
      logger :info, "Get host #{id}"
      send_zabbix('get_host', id)
    end

    def get_item(hostid, item)
      logger :info, "Get item #{hostid} #{item}"
      send_zabbix('get_item', hostid, item)
    end

    def get_history(params)
      logger :info, "Get histories #{params}"
      send_zabbix('get_history', params)
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

    def send_zabbix(action, *args)
      begin
        ds = DataStore.create(:mysql, {
            :database=> Dolphin.settings['zabbix']['database'],
            :host=> Dolphin.settings['zabbix']['host'],
            :port=> Dolphin.settings['zabbix']['port'],
            :user=> Dolphin.settings['zabbix']['user'],
            :password=> Dolphin.settings['zabbix']['password']
          })

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
