# -*- coding: utf-8 -*-

module Dolphin::Models
  module Rdb
    class Item < Base
      def get(hostid, item)
        res = db.find(:hostid=>hostid, :key_=>item)
        res.values
      end
    end
  end
end
