# -*- coding: utf-8 -*-

module Dolphin::Models
  module Rdb
    class Item < Base
      def get(hostid, item_key)
        res = db.find(:hostid=>hostid, :key_=>item_key)
        res.values
      end
    end
  end
end
