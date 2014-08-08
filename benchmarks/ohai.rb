#!/usr/bin/env ruby
# encoding: UTF-8

require 'socket'

delay = 0
verbose = false
host = "localhost"
port = 8888
puts "Starting simple, threaded TCP Server on http://#{host}:#{port}"

server = TCPServer.new host, port

begin
  loop do
    Thread.start(server.accept) do |client|
      request_lines = []
      while line = client.gets and line !~ /^\s*$/
        request_lines << line.chomp
      end
      puts request_lines.first if verbose
      sleep delay if delay > 0
      resp = "<html><body><h1>Time is #{Time.now}</h1></body></html>"
      headers = ["http/1.1 200 ok",
                 "content-type: text/html",
                 "content-length: #{resp.length}\r\n\r\n"].join("\r\n")
      client.puts headers
      client.puts resp
      client.close
      verbose ? puts("200 OK") : print('.')
    end
  end
rescue Interrupt
  puts "\nK Bye"
end
