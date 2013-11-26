# -*- coding: utf-8 -*-

module Dolphin::Helpers::Message
  module BrokenHelper
    def broken_message(str)
      str + nil
    end
  end
end
