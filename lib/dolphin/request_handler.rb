# -*- coding: utf-8 -*-

require 'reel'
require 'extlib/blank'
require 'sinatra/base'
require 'sinatra/respond_with'

module Dolphin
  class RequestHandler < Rack::Handler::Reel
    include Dolphin::Util

    def initialize(host, port)
      super({:host=>host, :port=>port, :app=>RequestApp.new})
      logger :info, "Load settings in #{Dolphin.config}"
    end

    def start
      Celluloid::Actor[:request_handler_rack_pool] = ::Reel::RackWorker.pool(size: options[:workers], args: [self])

      ::Reel::Server.supervise_as(:request_handler, options[:host], options[:port]) do |connection|
        Celluloid::Actor[:request_handler_rack_pool].handle(connection.detach)
      end
      logger :info, "Running on ruby #{RUBY_VERSION} with selected #{Celluloid::task_class}"
      logger :info, "Listening on http://#{options[:host]}:#{options[:port]}"
    end

    def stop
      Celluloid::Actor[:request_handler].terminate!
      Celluloid::Actor[:request_handler_rack_pool].terminate!
    end

    class RequestApp < Sinatra::Base
      include Dolphin::Util
      register Sinatra::RespondWith

      helpers do
        def required(name)
          case name
          when 'notification_id'
            raise 'Not found X-Notification-Id' if @notification_id.nil?
          end
        end

        def parse_time(time)
          return nil if time.blank? || !time.is_a?(String)
          Time.parse(URI.decode(time)).to_time
        end
      end
      
      respond_to :json
      GET_EVENT_LIMIT = 3000.freeze
      
      before do
        logger :info, {
          :host => request.host,
          :user_agent => request.user_agent
        }
        @notification_id = request.env['HTTP_X_NOTIFICATION_ID']
        @message_type = request.env['HTTP_X_MESSAGE_TYPE']

        if request.post?
          v = request.body
          @params = MultiJson.load(v)
        elsif request.get?
          @params = request.params
        end
      end

      error(RuntimeError) do
        status(400)
        respond_with {message:'Failed'}
      end

      post '/events' do
        raise 'Nothing parameters.' if @params.blank?
        
        event = {}
        event[:notification_id] = @notification_id
        event[:message_type] = @message_type
        event[:messages] = @params
        
        events = worker.future.put_event(event)
        
        # always success because put_event is async action.
        response_params = {
          :message => 'OK'
        }
        respond_with response_params
      end

      get '/events' do
        limit = @params['limit'].blank? ? GET_EVENT_LIMIT : @params['limit'].to_i
        raise "Requested over the limit. Limited to #{GET_EVENT_LIMIT}" if limit > GET_EVENT_LIMIT
        
        event = {}
        event[:count] = limit
        event[:start_time] = parse_time(@params['start_time']) unless @params['start_time'].blank?
        event[:start_id] = @params['start_id'] unless @params['start_id'].blank?
        
        events = worker.get_event(event)
        raise events.message if events.fail?
        
        response_params = {
          :results => events.message,
          :message => 'OK'
        }
        response_params[:start_time] = @params['start_time'] unless @params['start_time'].blank?
        respond_with response_params
      end

      get '/notifications' do
        required 'notification_id'
        
        notification = {}
        notification[:id] = @notification_id
        
        result = worker.get_notification(notification)
        raise result.message if result.fail?
        raise "Not found notification id" if result.message.nil?
        
        response_params = {
          :results => result.message,
          :message => 'OK'
        }
        respond_with response_params
      end

      post '/notifications' do
        required 'notification_id'
        raise 'Nothing parameters.' if @params.blank?
        
        unsupported_sender_types = @params.keys - Sender::TYPES
        raise "Unsuppoted sender types: #{unsupported_sender_types.join(',')}" unless unsupported_sender_types.blank?
        
        notification = {}
        notification[:id] = @notification_id
        notification[:methods] = @params
        result = worker.put_notification(notification)
        raise result.message if result.fail?
        
        response_params = {
          :message => 'OK'
        }
        respond_with response_params
      end

      delete '/notifications' do
        required 'notification_id'
        
        notification = {}
        notification[:id] = @notification_id
        
        result = worker.delete_notification(notification)
        raise result.message if result.fail?
        
        response_params = {
          :message => 'OK'
        }
        respond_with response_params
      end

      private
      def worker
        Celluloid::Actor[:workers]
      end
    end
  end
end
