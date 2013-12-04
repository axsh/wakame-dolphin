# -*- coding: utf-8 -*-

module Dolphin::Models
  module Rdb
    class History < Base
      def get(params)
        start_time = params[:start_time]
        end_time = params[:end_time]

        ds = db.filter(:itemid => params[:itemid])

        ds = if start_time && end_time
               if !(start_time < end_time)
                 raise "#{start_time} is larger then #{end_time}"
               end
               ds.filter("clock >= ?", start_time).filter("clock <= ?", end_time)
             elsif params[:start_time]
               ds.filter("clock >= ?", start_time)
             elsif params[:end_time]
               ds.filter("clock <= ?", end_time)
             else
               ds
             end
        ds.limit(params[:limit]).all.map { |h|
          h.values
        }
      end
    end
  end
end
