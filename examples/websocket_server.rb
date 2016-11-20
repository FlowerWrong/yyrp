$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'yyrp'
require 'eventmachine'
require 'websocket/driver'

module Connection
  def initialize
    @driver = WebSocket::Driver.server(self)

    @driver.on :connect, -> (event) do
      if WebSocket::Driver.websocket?(@driver.env)
        @driver.start
      else
        # handle other HTTP requests
      end
    end

    @driver.on :message, -> (e) {
      p 'on message'
      @driver.frame(e.data)
    }
    @driver.on :close,   -> (e) {
      p 'on close'
      close_connection_after_writing
    }
  end

  def receive_data(data)
    @client_port, @client_ip = Socket.unpack_sockaddr_in(get_peername)
    p "Received data from #{@client_ip}:#{@client_port}"
    p "Data is #{data}"
    @driver.parse(data)
  end

  def write(data)
    send_data(data)
  end
end

EM.run {
  host = '127.0.0.1'
  port = 7787
  p "Websocket server started on #{host}:#{port}"
  EM.start_server(host, port, Connection)
}
