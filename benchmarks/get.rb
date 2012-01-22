#!/usr/bin/env ruby
# encoding: UTF-8

$: << "#{File.dirname(__FILE__)}/../lib/"

require 'reactorb'
require 'socket'
require 'benchmark'

count   = 100
host    = 'www.google.com'
port    = '80'
request = "GET / HTTP/1.0\r\n\r\n"


puts "Serial requests:"
bytes   = ''
serial_sec = Benchmark.realtime do
  count.times do |i|
    io = TCPSocket.open(host, port)
    io.write request
    while !io.closed?
      io.eof? ? io.close : bytes << io.read
      print '.'
    end
  end
end
puts
puts "Read #{bytes.bytesize} bytes in %.4fsec serially" % serial_sec


puts "Reactor:"
bytes = ''
reactor_sec = Benchmark.realtime do
  Reactor.run do |reactor|
    count.times do |i|
      io = TCPSocket.open(host, port)
      reactor.attach io, :write do |write_io|
        io.write request
        reactor.detach(write_io)

        reactor.attach io, :read do |read_io|
          read_io.eof? ? read_io.close : bytes << read_io.read
          print '.'
        end
      end
    end
  end
end
puts
puts "Read #{bytes.bytesize} bytes in %.4fsec with reactor" % reactor_sec


if reactor_sec < serial_sec
  winner  = 'Reactor'
  diff    = serial_sec-reactor_sec
  percent = (100*diff/serial_sec)
else
  winner  = 'Serial'
  diff    = reactor_sec-serial_sec
  percent = (100*diff/reactor_sec)
end
puts "#{winner} was %.2fsec / %.2f%% faster" % [diff, percent]
