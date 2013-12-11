# -*- coding: utf-8 -*-

require 'spec_helper'

describe 'Event API' do

  GET_EVENT_LIMIT = 1.freeze

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
    response = get("/events?limit=#{GET_EVENT_LIMIT}", :headers => {
      'Content-Type' =>'application/json',
    })
    res = json_body(response.body)
    expect(res['message']).to eql 'OK'
  end

  it 'expect to get last event' do
    response = get("/events?limit=#{GET_EVENT_LIMIT}", :headers => {
      'Content-Type' =>'application/json',
    })
    res = json_body(response.body)
    last_event = res['results'][-1]
    last_event_id = last_event['id']

    query_string = '?' + [
      "limit=#{GET_EVENT_LIMIT}",
      "start_id=#{SimpleUUID::UUID.new(last_event_id).to_guid}"
    ].join('&')

    response = get('/events' + query_string, :headers => {
      'Content-Type' =>'application/json',
    })
    res = json_body(response.body)['results'][0]
    expect(res['id']).to eql last_event_id
  end

  it 'expect to post event and send email' do
    message_subject = 'subject'
    message_body = 'body'
    response = post('/events',
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
    res = json_body(response.body)

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

    expect(template).to be

    if template
      mail = Dolphin::Mailer.read_iso2022_jp_mail(@temporary_mail)
      expect(mail[:from]).to eql Dolphin.settings['mail']['from']
      expect(mail[:to]).to eql @mail_to
      expect(mail[:subject]).to eql template.subject
      expect(mail[:body]).to eql template.body
    end
  end

  it 'expect to post event only' do
    response = post('/events',
      :headers => {
        'Content-Type' =>'application/json',
      },
      :body => {
        'message' => 'Alert!!!!'
    }.to_json)
    res = json_body(response.body)
    expect(res['message']).to eql 'OK'
  end

  it 'fails to post with non json content-type' do
    content_type = 'application/x-www-form-urlencoded'
    response = post('/events',
      :headers => {
        'Content-Type' => content_type,
      },
      :body => {
        'message' => 'Alert!!!!'
      }.to_json)
    res = json_body(response.body)
    expect(res['message']).to eql "Unsupported Content Type: #{content_type}"
  end
  before(:all) do
    FileUtils.rm(@temporary_mail) if File.exists?(@temporary_mail)
  end

  it 'expect to fail to post invalid JSON in the POST body' do
    params = {:headers => {'Content-Type' =>'application/json'}}
    error_message = {"message" => 'Nothing parameters.'}

    evaluate = lambda {|body|
      begin
        response = post('/events', params.merge({:body => body.to_json}) )
      ensure
        res = json_body(response.body)
        return res
      end
    }

    expect(evaluate.call('')).to eql error_message
    expect(evaluate.call([])).to eql error_message
    expect(evaluate.call(nil)).to eql error_message
  end
end
