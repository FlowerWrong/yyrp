$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'yyrp'
require 'logging'

@pid_full = '/tmp/shadowsocks.pid'

def run
  EventMachine::run {
    server = Yyrp::ShadowsocksServer.new
    Signal.trap('INT') { stop }
    Signal.trap('TERM') { stop }

    if ENV['daemon'] == 'yes'
      log = Logging.logger['shadowsocks_log']
      log.add_appenders Logging.appenders.file('/tmp/shadowsocks.log')
      Yyrp.configure do |config|
        config.logger = log
        config.logger.level = :debug
      end
    end

    server.start
  }
end

def get_pid
  if File.exists?(@pid_full)
    file = File.new(@pid_full, 'r')
    pid = file.read
    file.close
    pid
  else
    0
  end
end

def start
  if ENV['daemon'] == 'yes'
    pid = get_pid
    if pid != 0
      warn 'Daemon is already running'
      exit -1
    end

    pid = fork {
      run
    }
    begin
      file = File.new(@pid_full, 'w')
      file.write(pid)
      file.close
      Process.detach(pid)
    rescue => exc
      Process.kill('TERM', pid)
      warn "Cannot start daemon: #{exc.message}"
    end
  else
    run
  end
end

def stop
  if ENV['daemon'] == 'yes'
    pid = get_pid
    begin
      EM.stop
    rescue => exc
      warn "Stop server exception: #{exc.message}"
    end

    if pid != 0
      Process.kill('HUP', pid.to_i)
      File.delete(@pid_full)
      warn 'Stopped'
    else
      warn 'Daemon is not running'
      exit -1
    end
  else
    begin
      EM.stop
    rescue => exc
      warn "Stop server exception: #{exc.message}"
    end
  end
end

# stop with `kill pid`
start
