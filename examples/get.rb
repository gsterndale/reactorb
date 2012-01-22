#!/usr/bin/env ruby
# encoding: UTF-8

$: << "#{File.dirname(__FILE__)}/../lib/"

require 'reactorb'
require 'socket'

host    = 'www.google.com'
port    = '80'
request = "GET / HTTP/1.0\r\n\r\n"
bytes   = ''

Reactor.run do |reactor|

  socket  = TCPSocket.open(host, port)
  reactor.attach socket, :write do |io|
    socket.write request
    reactor.detach(io)

    reactor.attach socket, :read do |io|
      io.eof? ? io.close : bytes << io.read
    end
  end

end

puts "Reactor stopped"
puts "Bytes read: #{bytes.bytesize}"
