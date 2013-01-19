require File.expand_path('spec/spec_helper')

describe WebCache::Server do
  it "starts and stops" do
    server = WebCache::Server.new('localhost', 8088, 0.001)
    server.should be_a_kind_of WebCache::Server
    server.stop
  end

  it "returns nil when there is no clients" do
    server = WebCache::Server.new('localhost', 8088, 0.001)
    socket = server.get_socket
    socket.should == nil
    server.stop
  end

  it "returns TCPSocket when there is a client" do
    server = WebCache::Server.new('localhost', 8088, 0.001)
    client = TCPSocket.new('localhost', '8088')
    client.send("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n", 0)
    client.shutdown
    socket = server.get_socket
    socket = server.get_socket
    socket.should be_a_kind_of TCPSocket
    r = socket.gets("\r\n", 1500)
    r.should == "GET / HTTP/1.1\r\n"
    server.stop
  end
end
