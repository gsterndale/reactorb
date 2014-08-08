#!/usr/bin/env ruby
# encoding: UTF-8

$: << "#{File.dirname(__FILE__)}/../lib/"

require 'reactorb'
require 'reactorb/http'
require 'uri'
require 'benchmark'

uri = URI.parse('http://localhost:8888')

fiberless_responses, fiber_responses = []

puts "\nWithout fibers reqeusts are done in series\n"
fiberless_sec = Benchmark.realtime do
  Reactor.run do |reactor|
    include Reactor::HTTP

    reactor.get uri do |response1|
      reactor.get uri do |response2|
        reactor.get uri do |response3|
          fiberless_responses = [response1, response2, response3]
          if fiberless_responses.all?{|r| r =~ /200 OK/i }
            puts "First #{fiberless_responses.size} fiberless responses are OK"
            reactor.get uri do |response4|
              fiberless_responses << response4
            end
          end
        end
      end
    end
  end
end

puts "\nWith fibers requests are done in parallel\n"
fiber_sec = Benchmark.realtime do
  Reactor.run do |reactor|
    include Reactor::HTTP

    fiber_responses = (1..3).map{ reactor.aget(uri) }
    puts "Three fiber requests made"
    if fiber_responses.all?{|r| r =~ /200 OK/i }
      puts "First #{fiber_responses.size} fiber responses are OK"
      fiber_responses << reactor.aget(uri)
    end
  end
end

puts "\nReactors stopped"
puts "#{fiberless_responses.size} fiberless responses"
puts "#{fiber_responses.size} fiber responses"
puts "%.4fsec without Fibers" % fiberless_sec
puts "%.4fsec with Fibers" % fiber_sec
