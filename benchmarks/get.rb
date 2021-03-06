#!/usr/bin/env ruby
# encoding: UTF-8

$: << "#{File.dirname(__FILE__)}/../lib/"

require 'reactorb'
require 'reactorb/http'
require 'socket'
require 'uri'
require 'benchmark'

host    = ARGV.shift || 'localhost'
count   = (ARGV.shift || 200).to_i
port    = '8888'
request = "GET / HTTP/1.0\r\n\r\n"
uri     = URI.parse("http://#{host}/")
CONNECTION_ERRORS = [ Errno::ECONNRESET, Errno::ECONNREFUSED ]

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
puts "Read #{bytes.bytesize} bytes in %.4fsec just TCPSockets (%.0f bytes/sec)" % [sockets_sec, bytes.bytesize / sockets_sec]


puts "Threaded requests:"
bytes   = ''
threads_sec = Benchmark.realtime do
  threads = (1..count).map do |i|
    Thread.new do
      io = TCPSocket.open(host, port)
      io.write request
      while !io.closed?
        begin
          io.eof? ? io.close : bytes << io.read
          print '.'
        rescue *CONNECTION_ERRORS
          print 'F'
        end
      end
    end
  end
  threads.map(&:join)
end
puts
puts "Read #{bytes.bytesize} bytes in %.4fsec TCPSockets with #{count} threads (%.0f bytes/sec)" % [threads_sec, bytes.bytesize / threads_sec]

require 'timeout'
puts "Thread pool requests:"
bytes   = ''
pool_sec = Benchmark.realtime do
  completes = 0
  threads = []
  i = 0
  pool_size = [count, 25].min
  begin
    Timeout::timeout(20) do
      while completes < count
        if i < count && threads.size < pool_size
          threads << Thread.new do
            me = (i += 1)
            io = TCPSocket.open(host, port)
            io.write request
            while !io.closed?
              io.eof? ? io.close : bytes << io.read
              print '.'
              # puts "- #{me} -"
            end
            completes += 1
          end
        end
        threads.select! { |thread| thread.alive? }
      end
    end
  rescue Timeout::Error
    puts 'timeout'
  end
end
puts
puts "Read #{bytes.bytesize} bytes in %.4fsec TCPSockets using a Thread pool (%.0f bytes/sec)" % [pool_sec, bytes.bytesize / pool_sec]


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
          begin
            read_io.eof? ? read_io.close : bytes << read_io.read
            print '.'
          rescue *CONNECTION_ERRORS
            print 'F'
          end
        end
      end
    end
  end
end
puts
puts "Read #{bytes.bytesize} bytes in %.4fsec with reactor and TCPSockets (%.0f bytes/sec)" % [reactor_sec, bytes.bytesize / reactor_sec]


puts "Reactor gets:"
bytes = ''
gets_sec = Benchmark.realtime do
  Reactor.run do |reactor|
    include Reactor::HTTP
    count.times do |i|
      begin
        reactor.get uri do |response|
          bytes << response
          print '.'
        end
      rescue *CONNECTION_ERRORS
        print 'F'
      end
    end
  end
end
puts
puts "Read #{bytes.bytesize} bytes in %.4fsec with reactor gets (%.0f bytes/sec)" % [gets_sec, bytes.bytesize / gets_sec]



puts "Reactor agets:"
bytes = ''
fiber_sec = Benchmark.realtime do
  Reactor.run do |reactor|
    include Reactor::HTTP
    (1..count).map do
      begin
        reactor.aget(uri)
      rescue *CONNECTION_ERRORS
        print 'F'
        ''
      end
    end.each do |response|
      bytes << response
      print '.'
    end
  end
end
puts
puts "Read #{bytes.bytesize} bytes in %.4fsec with reactor fiber agets (%.0f bytes/sec)" % [fiber_sec, bytes.bytesize / fiber_sec]

results = {
  'Serial Socket'   => sockets_sec,
  'Threads Socket'  => threads_sec,
  'Thread Pool'     => pool_sec,
  'Reactor Socket'  => reactor_sec,
  'Reactor Serial'  => gets_sec,
  'Reactor Fiber'   => fiber_sec,
}

results.each do |name, time|
  puts "#{name}:\t#{time}"
end
