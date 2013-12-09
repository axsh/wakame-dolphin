# -*- coding: utf-8 -*-

require 'parseconfig'
require 'ostruct'
require 'extlib/blank'

$LOAD_PATH.unshift File.expand_path('../', __FILE__)

module Dolphin
  def self.load_setting(path=nil)
    path ||= ENV['CONFIG_FILE'] || File.join(Dolphin.config_path, 'dolphin.conf')

    if !File.exists?(path)
      STDERR.puts "Not found configuration file: #{path}"
      exit!
    end

    @config = path
    @settings = ParseConfig.new(path)
  end

  def self.settings
    raise "Configuration file is not loaded yet." if @settings.nil?
    @settings
  end

  def self.config
    @config
  end

  def self.root_path
    File.expand_path('../../', __FILE__)
  end

  def self.templates_path
    File.join(root_path, '/templates')
  end

  def self.config_path
    File.join(root_path, '/config')
  end

  def self.db_path
    File.join(config_path, '/db')
  end

  class EventObject < OpenStruct;end
  class NotificationObject < OpenStruct; end
  class ResponseObject
    attr_accessor :message
    def initialize
      @success = nil
      @message = ''
    end

    def success!
      @success = true
    end

    def success?
      warn 'Does not happened anything.' if @success.nil?
      @success === true
    end

    def fail!
      @success = false
    end

    def fail?
      warn 'Does not happened anything.' if @success.nil?
      @success === false
    end
  end

  class FailureObject < ResponseObject
    def initialize(message = '')
      fail!
      @message = message
      freeze
    end
  end

  class SuccessObject < ResponseObject
    def initialize(message = '')
      success!
      @message = message
      freeze
    end
  end

  autoload :VERSION, 'dolphin/version'

  autoload :Util, 'dolphin/util'
  autoload :MessageBuilder, 'dolphin/message_builder'
  autoload :TemplateBuilder, 'dolphin/message_builder'
  autoload :Mailer, 'dolphin/mailer'
  autoload :DataStore, 'dolphin/data_store'

  module Models
    autoload :Base, 'dolphin/models/base'
    module Cassandra
      autoload :Base, 'dolphin/models/cassandra/base'
      autoload :Event, 'dolphin/models/cassandra/event'
      autoload :Notification, 'dolphin/models/cassandra/notification'
    end

    module Rdb
      autoload :Base, 'dolphin/models/rdb/base'
      autoload :Event, 'dolphin/models/rdb/event'
      autoload :Notification, 'dolphin/models/rdb/notification'
      module Orm
        autoload :Event, 'dolphin/models/rdb/orm/event'
        autoload :Notification, 'dolphin/models/rdb/orm/notification'
      end
    end
  end

  module Helpers
    autoload :RequestHelper, 'dolphin/helpers/request_helper'
    module Message
      autoload :ZabbixHelper, 'dolphin/helpers/message/zabbix_helper'
    end
  end

  module DataStore
    autoload :Cassandra, 'dolphin/data_stores/cassandra'
    autoload :Mysql, 'dolphin/data_stores/mysql'
    autoload :BaseRdb, 'dolphin/data_stores/base_rdb'
  end

  # Celluloid supervisor
  autoload :Manager, 'dolphin/manager'

  # Celluloid actors
  autoload :RequestHandler, 'dolphin/request_handler'
  autoload :Worker, 'dolphin/worker'
  autoload :QueryProcessor, 'dolphin/query_processor'
  autoload :Sender, 'dolphin/sender'

end
