# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'sinatra/respond_with'
require 'extlib/blank'

module Dolphin
  class RequestApp < Sinatra::Base
    class ClientError < RuntimeError; end
    class ServerError < RuntimeError; end
    class NotFound < RuntimeError; end

    use Dolphin::RequestHandler::CommonLogger
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
          unless @content_types.include?(env['CONTENT_TYPE'])
            return [415,
                    {'Content-Type'=>'application/json'},
                    [MultiJson.dump({
                      "message" => "Unsupported Content Type: #{env['CONTENT_TYPE']}"
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
      @notification_id = request.env['HTTP_X_NOTIFICATION_ID']
      @message_type = request.env['HTTP_X_MESSAGE_TYPE']

      if request.post?
        v = request.body
        begin
          @params = MultiJson.load(v)
          @params = {} if @params.blank?
        rescue => e
          raise ClientError, 'Invalid request parameters'
        end
      elsif request.get?
        @params = request.params
      end
    end

    error(ClientError) do |e|
      status(400)
      response_params =  {
        :message => e.message
      }
      response_error(response_params)
    end

    error(NotFound) do |e|
      status(404)
      response_params =  {
        :message => e.message
      }
      response_error(response_params)
    end

    error(ServerError) do |e|
      status(500)
      response_params =  {
        :message => e.message
      }
      response_error(response_params)
    end

    error do |e|
      response_params =  {
        :message => e.message
      }
      response_error(response_params)
    end

    not_found do |e|
      response_params =  {
        :message => 'Not found'
      }
      response_error(response_params)
    end

    post '/events' do
      raise ClientError, 'Nothing parameters.' if @params.blank?

      event = {}
      event[:notification_id] = @notification_id
      event[:message_type] = @message_type
      event[:messages] = @params

      events = worker.put_event(event)
      raise ServerError, events.message if events.fail?
      raise ClientError, events.message if events.not_found?

      response_params = {
        :message => 'OK'
      }
      respond_with response_params
    end

    get '/events' do
      limit = @params['limit'].blank? ? GET_EVENT_LIMIT : @params['limit'].to_i
      raise ClientError, "Requested over the limit. Limited to #{GET_EVENT_LIMIT}" if limit > GET_EVENT_LIMIT

      event = {}
      event[:count] = limit
      event[:start_time] = parse_time(@params['start_time']) unless @params['start_time'].blank?
      event[:start_id] = @params['start_id'] unless @params['start_id'].blank?

      events = worker.get_event(event)
      raise ServerError, events.message if events.fail?

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
      raise ServerError, result.message if result.fail?
      raise NotFound, "Not found notification id" if result.message.nil?

      response_params = {
        :results => result.message,
        :message => 'OK'
      }
      respond_with response_params
    end

    post '/notifications' do
      required 'notification_id'
      raise ClientError,'Nothing parameters.' if @params.blank?

      unsupported_sender_types = @params.keys - Sender::TYPES
      raise ClientError,"Unsuppoted sender types: #{unsupported_sender_types.join(',')}" unless unsupported_sender_types.blank?

      notification = {}
      notification[:id] = @notification_id
      notification[:methods] = @params
      result = worker.put_notification(notification)
      raise ServerError, result.message if result.fail?

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
      raise ServerError, result.message if result.fail?

      response_params = {
        :message => 'OK'
      }
      respond_with response_params
    end

    private
    def worker
      Celluloid::Actor[:workers]
    end

    def response_error(response_params)
      respond_with response_params
    end
  end
end
