# -*- coding: utf-8 -*-

require 'spec_helper'

describe 'Test Dolphin::Models for Cassandra' do
  before(:all) do
    @connection = Dolphin::DataStore::Cassandra.new(
      :keyspace => 'dolphin_test',
      :hosts => Dolphin.settings['database']['hosts'],
      :port => Dolphin.settings['database']['port']
    ).connect
    pending "Cassandra doens't exist" if @connection.nil?
  end

  describe Dolphin::Models::Cassandra::Event do

    before(:all) do
      @event_values = []
      @event_values << {
        'notification_id' => "system",
        'message_type' => "alert_port",
        'messages' => {
          "message"=>"Alert!!!!"
        }
      }

      @column_name = SimpleUUID::UUID.new(Time.now).to_guid
      @connection.insert(
        Dolphin::Models::Cassandra::Event::COLUMN_FAMILY,
        Dolphin::Models::Cassandra::Event::ROW_KEY,
        {@column_name => MultiJson.dump(@event_values)}
      )
    end

    subject(:event) {
      event = Dolphin::Models::Cassandra::Event.new
      event.instance_variable_set(:@connection, @connection)
      event
    }

    describe ".get" do
      let(:message) {
        res = event.get({:count=>1})
        message = res[0]
      }

      it "expect to get message id" do
        expect(message['id']).to eql SimpleUUID::UUID.new(message['id']).to_guid
      end

      it "expect to get message values" do
        expect(message['event']).to eql @event_values
      end

      it "expect to get message created_at formated by ISO8601" do
        expect(Time.iso8601(message['created_at'])).to be_instance_of Time
      end
    end

    describe '.put' do
      it "expect to put success" do
        event_id = event.put(@event_values[0])
        expect(SimpleUUID::UUID.new(event_id)).to be_a SimpleUUID::UUID
        event_data = event.get({
          :count => 1,
          :start_id => SimpleUUID::UUID.new(event_id)
        })[0]
        expect(event_id).to eql event_data['id']
      end
    end
  end

  context Dolphin::Models::Cassandra::Notification do

    before(:all) do
      if @connection

        @notification_values = {
          "email"=> {
            "to" => "foo@example.com,bar@example.com",
            "cc" => "foo@example.com,bar@example.com",
            "bcc" =>"foofoo@example.com,barbar@example.com"
          }
        }
        @row_key = 'system'
        @connection.insert('notifications', @row_key, {
          'methods' => MultiJson.dump(@notification_values)
        })
      end
    end

    subject(:notification) {
      notification = Dolphin::Models::Cassandra::Notification.new
      notification.instance_variable_set(:@connection, @connection)
      notification
    }

    let(:notification_data) do
      notification.get(@row_key)
    end

    describe '.get' do
      it "expect to the same values before created" do
        expect(notification_data).to eql @notification_values
      end
    end

    describe '.put' do
      let(:notification_new_data) do
        notification.put(@row_key, @notification_values)
      end

      it "expect to put success" do
        expect(notification_new_data).to be_nil

        notification_data = notification.get(@row_key)
        expect(notification_data).to eql @notification_values
      end
    end

    describe '.delete' do
      it "expect to delete success" do
        notification.put(@row_key, @notification_values)
        notification_new_data = notification.get(@row_key)
        expect(notification_new_data).to eql @notification_values

        deleted_notification = notification.delete(@row_key)
        expect(deleted_notification).to be_nil

        notification_data = notification.get(@row_key)
        expect(notification_data).to be_nil
      end
    end
  end
end
