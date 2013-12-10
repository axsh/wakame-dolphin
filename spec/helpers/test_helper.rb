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

  def close_wait_socket_count
    port = Dolphin.settings["server"]["port"]
    `ss -n | egrep #{port} | grep CLOSE-WAIT | wc -l`.strip.to_i
  end

  def run_server(options={})
    ## run command
    bundle = File.join(Dolphin.root_path, 'ruby/bin/bundle')
    dolphin = File.join(Dolphin.root_path, 'bin/dolphin_server')
    command =  "#{bundle} exec #{dolphin} -c #{options[:config_file]}"
    Process.spawn(command)
  end

  def test_runonce(options, &block)
    begin
      pid = run_server(options)
      # TODO: Fix waiting server
      sleep 5

      block.call
    rescue => e
      puts e
    ensure
      Process.kill("KILL", pid)
      puts "Process killed #{pid}"
    end
  end
end
