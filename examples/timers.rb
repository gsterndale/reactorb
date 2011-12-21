#!/usr/bin/env ruby
# encoding: UTF-8

$LOAD_PATH.unshift(File.dirname(__FILE__)+'/../lib/')
require 'reactorb'

n = 0

Reactor.new.run do |reactor|
  reactor.at(Time.now + 1) do
    puts "one"
    n += 1
  end

  reactor.in(2) do
    puts "two"

    reactor.in(1, n + 2) do |sum|
      puts "three"

      reactor.at(Time.now + 4, sum + 3) do |sum|
        puts "four"
        n = sum + 4
        puts n
      end
    end
  end
end

