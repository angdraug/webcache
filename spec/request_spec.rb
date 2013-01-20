require File.expand_path('spec/spec_helper')

describe WebCache::Request do
  it "can be initialized" do
    request = WebCache::Request.new(nil)
    request.should be_a_kind_of WebCache::Request
  end

  it "is not ready by default" do
    request = WebCache::Request.new(nil)
    request.should be_a_kind_of WebCache::Request
    request.ready?.should be_false
  end

  it "can read data from incoming connection" do
    incoming = StringIO.new("GET / HTTP/1.1\r\n")
    request = WebCache::Request.new(incoming)
    request.should be_a_kind_of WebCache::Request
    request.read_incoming
    request.ready?.should be_false
  end

  it "becomes ready after reading request from incoming connection" do
    incoming = StringIO.new("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n")
    request = WebCache::Request.new(incoming)
    request.should be_a_kind_of WebCache::Request
    request.read_incoming
    request.ready?.should be_true
  end

  it "can parse an HTTP request" do
    incoming = StringIO.new("GET http://localhost/ HTTP/1.1\r\nHost: localhost\r\n\r\n")
    request = WebCache::Request.new(incoming)
    request.should be_a_kind_of WebCache::Request
    request.read_incoming
    request.ready?.should be_true
    class << request
      public :parse
      attr_reader :method, :uri, :headers, :host, :port
    end
    request.parse
    request.method.should eq 'GET'
    request.uri.request_uri.should eq '/'
    request.uri.host.should eq 'localhost'
    request.uri.port.should eq 80
    request.headers['Host'].should eq 'localhost'
  end

  it "can serialize an HTTP response" do
    request = WebCache::Request.new('')
    request.should be_a_kind_of WebCache::Request
    class << request
      public :serialize
    end

    response = Object.new
    class << response
      def code; 200; end
      def message; 'OK'; end

      def canonical_each
        yield ['Content-Type', 'text/html']
      end

      def read_body
        '<html>test</html>'
      end
    end

    request.serialize(response).should eq "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n<html>test</html>"
  end

  it "can stream an HTTP response" do
    incoming = StringIO.new
    class << incoming
      def shutdown
        self.rewind
      end
    end

    request = WebCache::Request.new(incoming)
    request.should be_a_kind_of WebCache::Request
    class << request
      public :stream
    end

    response = Object.new
    class << response
      def Object.body_permitted?; true; end
      def code; 200; end
      def message; 'OK'; end

      def canonical_each
        yield ['Content-Type', 'text/html']
      end

      def read_body
        yield '<html>test</html>'
      end
    end

    request.stream(response)
    incoming.read.should eq "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n<html>test</html>"
  end
end
