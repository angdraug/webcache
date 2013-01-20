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
    @uri = nil
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
        log "Exception: " + e.inspect + "\n" + e.backtrace.join("\n")
        @incoming.shutdown
      end
    end
  end

  private

  def parse
    method, *header_lines = @buffer.split("\r\n")
    @method, request_uri, version = method.split(/\s+/)
    @uri = URI(request_uri)
    header_lines.each do |header_line|
      name, value = header_line.split(': ', 2)
      @headers[name] = value
    end
  end

  def cache
    Cache.instance
  end

  def serve
    if response = cache[@uri]
      log 'cache hit: ' + @uri.to_s
      send(response)
    else
      response = get_response
      if response.content_length and response.content_length < Cache::SIZE
        log 'cache miss: ' + @uri.to_s
        send(cache[@uri] = serialize(response))
      else
        log 'uncacheable: ' + @uri.to_s
        stream(response)
      end
    end
  end

  def get_response
    Net::HTTP.start(@uri.host, @uri.port) do |http|
      req = Net::HTTP::Get.new(@uri.request_uri)

      @headers.each do |name, value|
        next if %w[connection accept-encoding if-modified-since cache-control pragma].include?(name.downcase)
        req[name] = value
      end
      req['Connection'] = 'close'

      http.request(req)
    end
  end

  def banner(response)
    "HTTP/1.1 #{response.code} #{response.message}\r\n"
  end

  def header(response)
    header = ''
    response.canonical_each do |name, value|
      next if %w[connection transfer-encoding].include?(name.downcase)
      header << name + ': ' + value + "\r\n"
    end
    header << "Connection: close\r\n\r\n"
  end

  def serialize(response)
    message = banner(response)
    message << header(response)
    message << response.read_body
  end

  def stream(response)
    @incoming.write(banner(response))
    @incoming.write(header(response))

    if response.class.body_permitted?
      begin
        response.read_body do |chunk|
          @incoming.write(chunk)
        end
      rescue IOError
        @incoming.write(response.body)
      end
    end
    @incoming.shutdown
  end

  def send(message)
    @incoming.write(message)
    @incoming.shutdown
  end

  def log(message)
    STDERR << "WebCache Request: " + message + "\n"
    STDERR.flush
  end
end

end
