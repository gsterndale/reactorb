#!/usr/bin/env ruby
# encoding: UTF-8

$: << "#{File.dirname(__FILE__)}/../lib/"

require 'reactorb'
require 'socket'

begin

host     = '127.0.0.1'
port     = '4000'
server   = TCPServer.new(host, port)
template = '''HTTP/1.1 200 OK
Server: Reactorb
Connection: close
Content-Type: text/html

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head><title>Ohai</title></head>
<body>%s</body>
</html>
'''

puts "Reactor HTTP server running at http://#{host}:#{port}"
puts "CTRL-C to exit"

Reactor.run do |reactor|

  reactor.attach server, :read do |io|
    socket = io.accept
    path, verb = nil
    begin
      while !path
        /^(?<verb>GET|PUT|POST|DELETE|HEAD) (?<path>.+) HTTP/.match(socket.gets.chomp) do |m|
          path = m[:path]
          verb = m[:verb]
        end
      end
    rescue
    end
    code, response = case path
    when '/'
      [200, template % "Hello from Reactorb"]
    when /^\/about.*/
      [200, template % "About Reactorb"]
    when NilClass
      [400, "HTTP/1.1 400 Bad Request\n\n"]
    else
      [404, "HTTP/1.1 404 Not Found\n\n"]
    end
    sleep 0.1
    socket.write response
    socket.close
    puts "#{code} #{verb} #{path}"
  end

end

rescue Interrupt
  puts "\n"
end


puts "Reactor stopped"
