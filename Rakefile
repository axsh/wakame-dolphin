#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require "rubygems"
require "bundler/setup"

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'dolphin'

Dolphin.load_setting

require "rspec/core/rake_task"
desc 'Run rspec'
RSpec::Core::RakeTask.new("spec") do |spec|
  spec.pattern = FileList["spec/files/endpoint/*_spec.rb",
                          "spec/files/message_builder_spec.rb"]

  if Dolphin.settings['database']['adapter'] == 'cassandra'
    spec.pattern << 'spec/files/cassandra_models_spec.rb'
  end
end

task :default => :spec

namespace :db do
  namespace :cassandra do

    desc 'Clean cassandra'
    task :clean do |tasks|
      begin

      db_config = Dolphin.settings['database']
      @host = db_config['hosts'].split(',')[0]
      @port = db_config['port']

      @connect = Dolphin::DataStore::Cassandra.new({
        :keyspace => Dolphin::DataStore::Cassandra::KEYSPACE,
        :hosts => @host,
        :port => @port
      }).connect

        @connect.drop_keyspace(Dolphin::DataStore::Cassandra::KEYSPACE)
      rescue => e
        puts "Doesn't exist #{Dolphin::DataStore::Cassandra::KEYSPACE} keyspace or dropped already"
        exit
      end
    end

    desc 'Migrate cassandra'
    task :migrate do
      filename = Dolphin.db_path + '/cassandra_schema.txt'
      exec "/usr/bin/cassandra-cli -h #{@host} -p #{@port} -f #{filename}"
    end
  end

  namespace :mysql do

    desc 'Create all database tables'
    task :init do
      Dolphin::DataStore.current_store.connect
      Sequel.extension :migration
      Sequel::Migrator.apply(Sequel::DATABASES.first, File.expand_path('../config/db/sequel/migrations', __FILE__), 9999)
    end

    desc 'Drop all database tables'
    task :drop do
      Dolphin::DataStore.current_store.connect
      Sequel.extension :migration
      Sequel::Migrator.apply(Sequel::DATABASES.first, File.expand_path('../config/db/sequel/migrations', __FILE__), 0)
    end
  end
end
