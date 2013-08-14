# -*- coding: utf-8 -*-

require 'multi_json'

module Dolphin::Models
  module Rdb
    class Notification < Base
      def get(id)
        res = db.find(:uuid => id)
        if res
          MultiJson.load(res.value)
        end
      end

      def put(id, methods)
        d = db.find(:uuid => id)
        d = db.new if d.nil?
        d.uuid = id.to_s
        d.value = MultiJson.dump(methods)
        d.save
      end

      def delete(id)
        res = db.find(:uuid => id)
        res.destroy
      end
    end
  end
end
