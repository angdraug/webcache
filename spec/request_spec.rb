require File.expand_path('spec/spec_helper')

describe WebCache::Request do
  it "can be initialized" do
    request = WebCache::Request.new(nil)
    request.should be_a_kind_of WebCache::Request
  end

  it "is not ready by default" do
    request = WebCache::Request.new(nil)
    request.should be_a_kind_of WebCache::Request
    request.ready?.should == false
  end

  it "can read data from incoming connection" do
    incoming = StringIO.new("GET / HTTP/1.1\r\n")
    request = WebCache::Request.new(incoming)
    request.should be_a_kind_of WebCache::Request
    request.read_incoming
    request.ready?.should == false
  end

  it "becomes ready after reading request from incoming connection" do
    incoming = StringIO.new("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n")
    request = WebCache::Request.new(incoming)
    request.should be_a_kind_of WebCache::Request
    request.read_incoming
    request.ready?.should == true
  end

  it "can parse an HTTP request" do
    incoming = StringIO.new("GET http://localhost/ HTTP/1.1\r\nHost: localhost\r\n\r\n")
    request = WebCache::Request.new(incoming)
    request.should be_a_kind_of WebCache::Request
    request.read_incoming
    request.ready?.should == true
    class << request
      public :parse
      attr_reader :method, :uri, :headers, :host, :port
    end
    request.parse
    request.method.should == 'GET'
    request.uri.request_uri.should == '/'
    request.uri.host.should == 'localhost'
    request.uri.port.should == 80
    request.headers['Host'].should == 'localhost'
  end
end
