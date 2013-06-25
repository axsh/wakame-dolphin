module TestHelper
  def wait_for_sending_mail_to_be_ready(timeout = 5, sleep_time = 1, &block)
    if block_given? &block
      waiting_count = 0
      loop do
        block.call

        if waiting_count > timeout
          puts "wait timeout #{timeout}"
          break
        end

        puts "sleep #{sleep_time} wait..#{waiting_count}"
        sleep sleep_time
        waiting_count +=1
      end
    else
      sleep sleep_time
    end
  end
end