# -*- coding: utf-8 -*-

require 'spec_helper'

describe 'Notification API' do
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

  it 'expect to get notifications' do
    response = get('/notifications', :headers => {
      'Content-Type' =>'application/json',
      'X-Notification-Id' => @notification_id,
    })
    res = json_body(response.body)
    expect(res['results']).to eql @notification_values
    expect(res['message']).to eql 'OK'
  end

  it 'expect to post notification' do
    response = post('/notifications',
      :headers => {
        'Content-Type' =>'application/json',
        'X-Notification-Id' => @notification_id
      },
      :body => @notification_values.to_json
    )
    res = json_body(response.body)
    expect(res['message']).to eql 'OK'
  end

  it 'expect to delete notification' do
    response = delete('/notifications', :headers => {
      'Content-Type' =>'application/json',
      'X-Notification-Id' => @notification_id,
    })
    res = json_body(response.body)
    expect(res['message']).to eql 'OK'
  end

end
