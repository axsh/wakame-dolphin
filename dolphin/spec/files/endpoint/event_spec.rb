# -*- coding: utf-8 -*-

require 'spec_helper'

describe 'Event API' do

  before(:all) do

    # Mail Setting
    output_mail_file_location = '/var/tmp/'

    @mail_to = "test_to@example.com"
    @temporary_mail = "#{output_mail_file_location}#{@mail_to}"

    @connection = Dolphin::DataStore.current_store
    @connection.connect

    if @connection.closed?
      pending "Failed cannect to database"
    else
      @notification_id = 'system'
      @notification_values = {
        "email"=> {
          "to" => @mail_to,
        }
      }
      @notification_id = 'test'
      @connection.put_notification(@notification_id, @notification_values)

      @message_type = "default"
      @event_values = {
        'notification_id' => @notification_id,
        'message_type' => @message_type,
        'messages' => {
          "message"=>"Alert!!!!"
        }
      }

      @connection.put_event({:messages => @event_values})
    end
  end

  it 'expect to get events' do
    res = get('/events', :headers => {
      'Content-Type' =>'application/json',
    })
    expect(res['message']).to eql 'OK'
  end

  it 'expect to get last event' do
    events = get('/events', :headers => {
      'Content-Type' =>'application/json',
    })
    last_event = events['results'][-1]
    last_event_id = last_event['id']

    query_string = '?' + [
      "count=1",
      "start_id=#{SimpleUUID::UUID.new(last_event_id).to_guid}"
    ].join('&')

    res = get('/events' + query_string, :headers => {
      'Content-Type' =>'application/json',
    })['results'][0]
    expect(res['id']).to eql last_event_id
  end

  it 'expect to post event and send email' do
    message_subject = 'subject'
    message_body = 'body'
    res = post('/events',
      :headers => {
        'Content-Type' =>'application/json',
        'X-Notification-Id' => @notification_id,
        'X-Message-Type' => @message_type
      },
      :body => {
        'subject' => message_subject,
        'body' => message_body,
        'message' => 'Alert!!!!'
    }.to_json)

    expect(res['message']).to eql 'OK'

    wait_for_sending_mail_to_be_ready {
      break if File.exists?(@temporary_mail)
    }

    mb = Dolphin::MessageBuilder::Mail.new
    template = mb.build(@message_type, {
      'messages' => {
        'subject' => message_subject,
        'body' => message_body,
      },
      'mail' => {
        'from' => Dolphin.settings['mail']['from']
      },
      'to' => @mail_to
    })

    mail = Dolphin::Mailer.read_iso2022_jp_mail(@temporary_mail)
    expect(mail[:from]).to eql Dolphin.settings['mail']['from']
    expect(mail[:to]).to eql @mail_to
    expect(mail[:subject]).to eql template.subject
    expect(mail[:body]).to eql template.body
  end

  it 'expect to post event only' do
    res = post('/events',
      :headers => {
        'Content-Type' =>'application/json',
      },
      :body => {
        'message' => 'Alert!!!!'
    }.to_json)

    expect(res['message']).to eql 'OK'
  end

  before(:all) do
    FileUtils.rm(@temporary_mail) if File.exists?(@temporary_mail)
  end
end