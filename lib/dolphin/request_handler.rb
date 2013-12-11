# -*- coding: utf-8 -*-

require 'rack'
require 'reel/rack/server'
require 'rack/body_proxy'
require 'extlib/blank'
require 'sinatra/base'
require 'sinatra/respond_with'

module Rack
  class BodyProxy
    include Enumerable
  end
end

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

    # The code in CommonLogger is copied almost verbatim from rack/common_logger which is made available
    # under the following terms:
    # Copyright (c) 2007, 2008, 2009, 2010, 2011, 2012 Christian Neukirchen <purl.org/net/chneukirchen>
    #
    # Permission is hereby granted, free of charge, to any person obtaining a copy
    # of this software and associated documentation files (the "Software"), to
    # deal in the Software without restriction, including without limitation the
    # rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
    # sell copies of the Software, and to permit persons to whom the Software is
    # furnished to do so, subject to the following conditions:
    #
    # The above copyright notice and this permission notice shall be included in
    # all copies or substantial portions of the Software.
    #
    # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    # THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    # IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    # CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    # Rack::CommonLogger forwards every request to the given +app+, and
    # logs a line in the
    # {Apache common log format}[http://httpd.apache.org/docs/1.3/logs.html#common]
    # to the +logger+.
    #
    # If +logger+ is nil, CommonLogger will fall back +rack.errors+, which is
    # an instance of Rack::NullLogger.
    #
    # +logger+ can be any class, including the standard library Logger, and is
    # expected to have a +write+ method, which accepts the CommonLogger::FORMAT.
    # According to the SPEC, the error stream must also respond to +puts+
    # (which takes a single argument that responds to +to_s+), and +flush+
    # (which is called without arguments in order to make the error appear for
    # sure)
    class CommonLogger
      # Common Log Format: http://httpd.apache.org/docs/1.3/logs.html#common
      #
      #   lilith.local - - [07/Aug/2006 23:58:02] "GET / HTTP/1.1" 500 -
      #
      #   %{%s - %s [%s] "%s %s%s %s" %d %s\n} %
      FORMAT = %{[%s] [%s] %s "%s %s%s %s" %d %s %0.4f "%s"}

      def initialize(app, logger=nil)
        @app = app
        @logger = logger
      end

      def call(env)
        began_at = Time.now
        status, header, body = @app.call(env)
        header = Rack::Utils::HeaderHash.new(header)
        body = Rack::BodyProxy.new(body) { log(env, status, header, began_at) }
        [status, header, body]
      end

      private

      def log(env, status, header, began_at)
        now = Time.now
        length = extract_content_length(header)

        logger = @logger || Celluloid.logger
        logger.info FORMAT % [
          Thread.current.object_id,
          @app.instance_variable_get('@app').class.to_s,
          env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"] || "-",
          env["REQUEST_METHOD"],
          env["PATH_INFO"],
          env["QUERY_STRING"].empty? ? "" : "?"+env["QUERY_STRING"],
          env["HTTP_VERSION"],
          status.to_s[0..3],
          length,
          now - began_at,
          env["HTTP_USER_AGENT"],
          ]
      end

      def extract_content_length(headers)
        value = headers['Content-Length'] or return '-'
        value.to_s == '0' ? '-' : value
      end
    end
  end

  class RequestApp < Sinatra::Base
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
          raise 'Invalid request parameters'
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
