# -*- coding: utf-8 -*-

require 'reel/rack/server'
require 'extlib/blank'
require 'sinatra/base'
require 'sinatra/respond_with'

module Dolphin
  #class RequestHandler < Rack::Handler::Reel
  class RequestHandler < Reel::Rack::Server
    include Dolphin::Util
    
    def initialize(host, port)
      # Default env is production.
      ENV['RACK_ENV'] ||= 'production'

      super(RequestApp.new, {:Host=>host, :Port=>port})
      logger :info, "Load settings in #{Dolphin.config}"
      logger :info, "Running on ruby #{RUBY_VERSION} with selected #{Celluloid::task_class}"
      logger :info, "Listening on http://#{host}:#{port}"
    end
  end

  class RequestApp < Sinatra::Base
    include Dolphin::Util
    helpers Dolphin::Helpers::RequestHelper
    register Sinatra::RespondWith
    respond_to :json
    set :show_exceptions, false

    # Rack middleware that rejects the request with unsupported content type.
    # Returns 415 (Unsupported Media Type) for the unsupported request.
    #
    # Rack's nested param parser gets crashed from the request of
    # incompatible header and body pair. so this middleware validates the request
    # earlier than the parser runs.
    class ValidateContentType
      def initialize(app, content_types=[])
        @app = app
        @content_types = content_types
      end

      def call(env)
        if env['REQUEST_METHOD'] == 'POST'
          # env['CONTENT_TYPE'] is not sent from reel-rack 0.1 due to
          # its regression. so needs to take care for both cases.
          request_content_type = (env['CONTENT_TYPE'] || env['HTTP_CONTENT_TYPE'])
          unless @content_types.find{ |c| c.downcase == request_content_type.downcase }
            return [415,
                    {'Content-Type'=>'application/json'},
                    [MultiJson.dump({
                      "message" => "Unsupported Content Type: #{request_content_type}"
                    })]
                  ]
          end
        end
        @app.call(env)
      end
    end
    use ValidateContentType, ['application/json', 'text/json'].freeze

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
        begin
          @params = MultiJson.load(v)
        rescue => e
          raise e.message.split(':')[1].strip!
        end
      elsif request.get?
        @params = request.params
      end
    end

    error(RuntimeError) do |e|
      status(400)
      response_params =  {
        :message => e.message
      }
      respond_with response_params
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
