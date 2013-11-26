# -*- coding: utf-8 -*-

require 'spec_helper'

describe 'Test Dolphin' do

  before(:all) do

    @connection = Dolphin::DataStore.current_store
    @connection.connect
    if @connection.closed?
      pending "Failed cannect to database"
    else
      @notification_values = {
        "email"=> {
          "to" => "foo@example.com,bar@example.com",
          "cc" => "foo@example.com,bar@example.com",
          "bcc" =>"foofoo@example.com,barbar@example.com"
        }
      }
      @notification_id = 'system'
      @connection.put_notification(@notification_id, @notification_values)
    end
  end

  it 'expect to not remain close socket' do
    res = get('/notifications', :headers => {
      'Content-Type' =>'application/json',
      'X-Notification-Id' => @notification_id,
    })

    expect(res['message']).to eql 'OK'
    expect(close_wait_socket_count).to eql 0
  end

end
