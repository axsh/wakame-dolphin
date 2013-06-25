# -*- coding: utf-8 -*-

require 'multi_json'
require 'simple_uuid'

module Dolphin::Models
  module Rdb
    class Event < Base
      def get(params)
        options = {
          :count => params[:count]
        }

        if params[:start_id]
          options[:start] = params[:start_id]
        elsif params[:start_time]
          options[:start] = params[:start_time]
        end

        if options[:start]
          event = db.find(:uuid => params[:start_id])
          h = {}
          h['id'] = event.uuid
          h['event'] = MultiJson.load(event.value)
          h['created_at'] = SimpleUUID::UUID.new(event.uuid).to_time.iso8601
          [h]
        else
          db.order(Sequel.desc(:id)).find_all.collect do |event| {
            'id' => event.uuid,
            'event' => MultiJson.load(event.value),
            'created_at' => SimpleUUID::UUID.new(event.uuid).to_time.iso8601
          }
          end
        end
      end

      def put(event)
        d = db.new
        d.uuid = SimpleUUID::UUID.new(Time.now).to_guid
        d.value = MultiJson.dump(event[:messages])
        d.timestamp = DateTime.now
        d.save
        d.uuid
      end
    end
  end
end
