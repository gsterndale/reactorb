#!/usr/bin/env ruby
# encoding: UTF-8

$: << "#{File.dirname(__FILE__)}/../lib/"

require 'reactorb'
require 'socket'

socket = TCPSocket.open('gregsterndale.com', '80')
response = ''

Reactor.new.run do |reactor|

  reactor.attach socket, :write do |io|
    socket.write "GET / HTTP/1.0\r\n\r\n"
    puts 'wrote'
    reactor.detach(io)

    reactor.attach socket, :read do |io|
      if io.eof?
        io.close
        next
      end
      chunk = io.read_nonblock(1448)
      puts "read #{chunk.bytesize}"
      response << chunk
    end
  end

end

puts "Reactor stopped"
puts "Response size: #{response.bytesize}"
