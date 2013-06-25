# -*- coding: utf-8 -*-

require 'celluloid'
require 'extlib/blank'
require 'time'

module Dolphin
  module Sender
    TYPES = ['email'].freeze

    TYPE = [:mail_senders].freeze

    class Mail
      include Celluloid
      include Dolphin::Util

      def notify(notification_object)
        time_now = DateTime.now.strftime('%a, %d %b %Y %H:%M:%S %z')
        send_params = {
          :from => notification_object.from,
          :to => notification_object.to,
          :subject => notification_object.subject,
          :body => notification_object.body,
          :date => time_now,
          :event_id => notification_object.event_id
        }

        unless notification_object.to.blank?
          send_params[:cc] = notification_object.cc
        end

        unless notification_object.bcc.blank?
          send_params[:bcc] = notification_object.bcc
        end

        logger :info, send_params
        begin
          Mailer.notify(send_params)
          logger :info, "Success Sent message"
        rescue => e
          logger :error, e.message
        end

      end
    end
  end
end
