# -*- coding: utf-8 -*-

require 'spec_helper'

describe 'Test Reel version 0.0.3 bug' do

  before(:all) do

    @adapter = Dolphin.settings['database']['adapter']
    @host = Dolphin.settings['server']['host']
    @port = Dolphin.settings['server']['port']

    Dolphin.settings['database']['adapter'] = 'mock'
    Dolphin.settings['server']['host'] = '127.0.0.1'
    Dolphin.settings['server']['port'] = 9005


    @connection = Dolphin::DataStore.current_store
    @connection.connect
    if @connection.closed?
      raise "Failed cannect to database"
    else
      @notification_values = {
        "email"=> {
          "to" => "foo@example.com,bar@example.com",
          "cc" => "foo@example.com,bar@example.com",
          "bcc" =>"foofoo@example.com,barbar@example.com"
        }
      }
      @notification_id = '0'
      @connection.put_notification(@notification_id, @notification_values)


      @server_options = {
        :config_file => File.join(Dolphin.config_path, 'dolphin-test.conf')
      }
    end
  end

  it 'expect to not remain close socket use Net::HTTP' do
    test_runonce(@server_options) {
      response = get('/notifications', :headers => {
        'Content-Type' =>'application/json',
        'X-Notification-Id' => @notification_id,
      })
      res = json_body(response.body)
      expect(res['message']).to eql 'OK'
      expect(close_wait_socket_count).to eql 0
      expect(response.code).to eql '200'
    }
  end

  it 'expect to not remain close socket use TCPSocket' do
    test_runonce(@server_options) {
      require "socket"
      sock = TCPSocket.open(Dolphin.settings['server']['host'], Dolphin.settings['server']['port'])
      sock.close
      expect(close_wait_socket_count).to eql 0
    }
  end

  it 'expect to not remain close socket use curl command' do
    test_runonce(@server_options) {
      curl = '/usr/bin/curl -s'
      command = "#{curl} -X GET http://#{Dolphin.settings['server']['host']}:#{Dolphin.settings['server']['port']}/notifications "
      command += "-H 'Content-Type: application/json' "
      command += "-H 'X-Notification-Id: #{@notification_id}'"
      command += ' > /dev/null'
      system(command)
      expect(close_wait_socket_count).to eql 0
    }
  end

  after(:all) do
    Dolphin.settings['database']['adapter'] = @adapter
    Dolphin.settings['server']['host'] = @host
    Dolphin.settings['server']['port'] = @port
  end
end

