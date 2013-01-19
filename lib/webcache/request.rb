# WebCache Request
#
#   Copyright (c) 2013  Dmitry Borodaenko <angdraug@debian.org>
#
#   This program is free software.
#   You can distribute/modify this program under the terms of
#   the GNU General Public License version 3 or later.
#
# vim: et sw=2 sts=2 ts=8 tw=0

require 'net/http'

module WebCache

class Request
  BUFFER_SIZE = 4096

  def initialize(socket)
    @incoming = socket
    @buffer = ''
    @ready = false
    @method = nil
    @request_uri = nil
    @headers = {}
    @host = nil
    @port = nil
  end

  def read_incoming
    @buffer << @incoming.gets("\r\n\r\n", BUFFER_SIZE)
    if @buffer.chomp!("\r\n\r\n")
      @ready = true
    end
  end

  def ready?
    @ready
  end

  def start
    Thread.start do
      begin
        parse
        serve
      rescue Exception => e
        log "Exception: " + e.inspect + e.backtrace.join("\n")
      end
    end
  end

  private

  def parse
    method, *header_lines = @buffer.split("\r\n")
    @method, @request_uri, version = method.split(/\s+/)
    header_lines.each do |header_line|
      name, value = header_line.split(': ', 2)
      @headers[name] = value
    end
    @host, @port = @headers['Host'].split(':', 2)
    @port ||= 80
  end

  def serve
    req = Net::HTTP::Get.new(@request_uri)
    @headers.each do |name, value|
      next if %w[connection accept-encoding if-modified-since cache-control pragma].include?(name.downcase)
      log name + ': ' + value
      req[name] = value
    end
    req['Connection'] = 'close'

    response = Net::HTTP.start(@host, @port) do |http|
      http.request(req)
    end

    process_response(response)
  end

  def process_response(response)
    @incoming.write("HTTP/1.1 200 OK\r\n")

    response.canonical_each do |name, value|
      @incoming.write(name + ': ' + value + "\r\n") unless name.downcase == 'connection'
    end
    @incoming.write("Connection: close\r\n\r\n")

    @incoming.write(response.read_body)
    @incoming.shutdown
  end

  def log(message)
    STDERR << "WebCache Request: " << message + "\n"
  end
end

end
