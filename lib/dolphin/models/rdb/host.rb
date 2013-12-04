# -*- coding: utf-8 -*-

module Dolphin::Models
  module Rdb
    class Host < Base
      def get(id)
        res = db.find(:host=>id)
        res.values
      end
    end
  end
end
