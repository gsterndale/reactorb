#!/usr/bin/env ruby
# encoding: UTF-8

require 'socket'

server = TCPServer.new "localhost", 8888

begin
  loop do
    Thread.start(server.accept) do |client|
      client.puts "Hello!"
      client.puts "Time is #{Time.now}"
      client.close
      print '.'
    end
  end
rescue Interrupt
  puts "\nK Bye"
end
