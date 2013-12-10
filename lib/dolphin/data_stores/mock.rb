module Dolphin
  module DataStore
    class Mock

      def initialize(config)
      end

      def connect
      end

      def closed?
        false
      end

      def get_notification(id)
        o = OpenStruct.new
        o.message = {"email"=> {
          "to" => "foo@example.com",
          "cc" => "foo@example.com",
         "bcc" => "foofoo@example.com"
         }
       }
      end

      def put_event(event)
      end

      def get_event(params)
      end

      def put_notification(id, methods)
      end

      def delete_notification(notification)
      end
    end
  end
end
