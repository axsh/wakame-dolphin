# -*- coding: utf-8 -*-

require 'rack'
require 'rack/body_proxy'
require 'reel/rack/server'

module Rack
  class BodyProxy
    include Enumerable
  end
end

module Dolphin
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
end
