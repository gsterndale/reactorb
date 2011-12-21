#!/usr/bin/env ruby
# encoding: UTF-8

$LOAD_PATH.unshift(File.dirname(__FILE__)+'/../lib/')
require 'reactorb'

message = ['0'..'9', 'A'..'Z', 'a'..'z'].map(&:to_a).flatten.join

reader, writer = IO.pipe

Reactor.new.run do |reactor|

  reactor.attach writer, :write do |write_io|
    chunk = message.slice!(0..9)
    write_io.write chunk
    puts "Wrote:\t#{chunk}"
    write_io.close if message.empty?
  end

  reactor.attach reader, :read do |read_io|
    if read_io.eof?
      read_io.close
    else
      puts "Read:\t#{read_io.read 5}"
    end
  end

end
