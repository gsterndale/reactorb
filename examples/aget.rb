#!/usr/bin/env ruby
# encoding: UTF-8

$: << "#{File.dirname(__FILE__)}/../lib/"

require 'reactorb'
require 'reactorb/http'
require 'uri'

uri = URI.parse('http://www.google.com/')

serial_responses, responses = []

Reactor.run do |reactor|
  include Reactor::HTTP

  reactor.get uri do |response1|
    reactor.get uri do |response2|
      reactor.get uri do |response3|
        serial_responses = [response1, response2, response3]
        if serial_responses.all?{|r| r =~ /200 OK/ }
          puts "First #{serial_responses.size} serial_responses are OK"
          reactor.get uri do |response4|
            serial_responses << response4
          end
        end
      end
    end
  end

  responses = (1..3).map{ reactor.aget(uri) }
  if responses.all?{|r| r =~ /200 OK/ }
    puts "First #{responses.size} responses are OK"
    responses << reactor.aget(uri)
  end

end

puts
puts "Reactor stopped"
puts "#{serial_responses.size} serial responses"
puts "#{responses.size} responses"
#puts responses.map{|response| response[0..14] }.join("\n")

