#!/usr/bin/env ruby
# encoding: UTF-8

$: << "#{File.dirname(__FILE__)}/../lib/"

require 'reactorb'
require 'reactorb/http'
require 'socket'
require 'uri'
require 'benchmark'

count   = 200
host    = 'localhost'#'www.gregsterndale.com'
port    = '80'
request = "GET / HTTP/1.0\r\n\r\n"
uri     = URI.parse("http://#{host}/")


puts "TCPSockets:"
bytes   = ''
sockets_sec = Benchmark.realtime do
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
puts "Read #{bytes.bytesize} bytes in %.4fsec just TCPSockets (%.0fbytes/sec)" % [sockets_sec, bytes.bytesize / sockets_sec]


# puts "Threaded requests:"
# raise "TODO"


puts "Reactor TCPSockets:"
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
puts "Read #{bytes.bytesize} bytes in %.4fsec with reactor and TCPSockets (%.0fbytes/sec)" % [reactor_sec, bytes.bytesize / reactor_sec]


puts "Reactor gets:"
bytes = ''
gets_sec = Benchmark.realtime do
Reactor.run do |reactor|
  include Reactor::HTTP
  count.times do |i|
    reactor.get uri do |response|
      bytes << response
      print '.'
    end
  end
end
end
puts
puts "Read #{bytes.bytesize} bytes in %.4fsec with reactor gets (%.0fbytes/sec)" % [gets_sec, bytes.bytesize / gets_sec]



puts "Reactor agets:"
bytes = ''
fiber_sec = Benchmark.realtime do
Reactor.run do |reactor|
  include Reactor::HTTP
  (1..count).map{ reactor.aget(uri) }.each{|response| bytes << response; print '.' }
end
end
puts
puts "Read #{bytes.bytesize} bytes in %.4fsec with reactor fiber gets (%.0fbytes/sec)" % [fiber_sec, bytes.bytesize / fiber_sec]

results = {
  'Serial Socket'  => sockets_sec,
  'Reactor Socket' => reactor_sec,
  'Reactor Serial'  => gets_sec,
  'Reactor Fiber'  => fiber_sec,
}

results.each do |name, time|
  puts "#{name}:\t#{time}"
end
