# WebCache Server
#
#   Copyright (c) 2013  Dmitry Borodaenko <angdraug@debian.org>
#
#   This program is free software.
#   You can distribute/modify this program under the terms of
#   the GNU General Public License version 3 or later.
#
# vim: et sw=2 sts=2 ts=8 tw=0

require 'socket'

module WebCache

class Server
  TICK = 0.04

  def initialize(host, port, timeout)
    @host = host
    @port = port
    @server = TCPServer.new(@host, @port)
    @timeout = timeout
    @connections = []
    @requests = {}
  end

  def get_socket
    inputs, outputs, errors = select([@server] + @connections, nil, @connections, @timeout)
    check_errors(errors) if errors
    check_inputs(inputs) if inputs
  end

  def run
    loop do
      unless socket = get_socket
        sleep TICK
        next
      end

      unless request = @requests[socket]
        request = @requests[socket] = Request.new(socket)
      end

      request.read_incoming
      if request.ready?
        socket.close_read
        @connections.delete(socket)
        @requests.delete(socket)
        request.start
      end
    end
  end

  def stop
    @server.close
  end

  private

  def check_errors(errors)
    errors.each do |socket|
      socket.close
      @connections.delete(socket)
      log("Socket error: " << Helper.socket_peer(socket))
    end
  end

  def check_inputs(inputs)
    inputs.each do |socket|
      if socket == @server
        accept
      elsif socket.eof?
        @connections.delete(socket)
      else
        return socket
      end
    end
    return nil
  end

  def accept
    client = @server.accept
    if client
      @connections << client
    else
      log("Incoming connection failed: " << Helper.socket_peer(socket))
    end
  end

  def log(message)
    STDERR << "WebCache Server: " << message + "\n"
  end
end

end
