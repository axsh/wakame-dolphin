# -*- coding: utf-8 -*-

require 'spec_helper'

describe 'Notification API' do
  before(:all) do

    # TODO: Change keyspace for test
    @connection = Dolphin::DataStore::Cassandra.new(
      :keyspace => 'dolphin',
      :hosts => Dolphin.settings['database']['hosts'],
      :port => Dolphin.settings['database']['port']
    ).connect
    pending "Cassandra doens't exist" if @connection.nil?

    if @connection
      @notification_values = {
        "email"=> {
          "to" => "foo@example.com,bar@example.com",
          "cc" => "foo@example.com,bar@example.com",
          "bcc" =>"foofoo@example.com,barbar@example.com"
        }
      }
      @notification_id = 'system'
      @connection.insert('notifications', @notification_id, {
        'methods' => MultiJson.dump(@notification_values)
      })
    end
  end

  it 'expect to get notifications' do
    res = get('/notifications', :headers => {
      'Content-Type' =>'application/json',
      'X-Notification-Id' => @notification_id,
    })

    expect(res['results']).to eql @notification_values
    expect(res['message']).to eql 'OK'
  end

  it 'expect to post notification' do
    res = post('/notifications',
      :headers => {
        'Content-Type' =>'application/json',
        'X-Notification-Id' => @notification_id
      },
      :body => @notification_values.to_json
    )
    expect(res['message']).to eql 'OK'
  end

  it 'expect to delete notification' do
    res = delete('/notifications', :headers => {
      'Content-Type' =>'application/json',
      'X-Notification-Id' => @notification_id,
    })
    expect(res['message']).to eql 'OK'
  end

end