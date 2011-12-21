require 'reactorb/callback_registry'

class Reactor

  attr_reader :timers
  attr_reader :ios
  EVENTS = [:read, :write, :error].freeze

  def self.now
    Time.now.to_i
  end

  def initialize
    @running = false
    @timers = CallbackRegistry.new
    @ios = Hash.new do |h, k|
      h[k] = {:events => [], :callbacks => {}, :args => []}
    end
  end

  def running?
    !!@running
  end

  def run
    @running = true
    yield self if block_given?
    while self.running? do
      self.tick
      self.stop if self.empty?
    end
  end

  def stop
    @running = false
  end

  def tick
    @tick_time = self.class.now.to_i
    self.trim_events
    self.handle_events
    self.handle_timers
    @tick_time = nil
  end

  def at(time_or_number, *args, &handler)
    @timers[time_or_number.to_i] << [handler, args]
  end

  def attach(io, *args, &handler)
    events = EVENTS & args # intersection
    @ios[io].tap do |registry|
      registry[:events] |= events # append new, unique values
      registry[:args] = args - events
      events.each {|event| registry[:callbacks][event] = handler }
    end
  end

  def detach(io)
    @ios.delete io
  end

  def empty?
    @ios.empty? && @timers.empty?
  end

protected

  attr_reader :tick_time

  def handle_timers
    while @timers.any? && @timers.first_key <= self.tick_time
      @timers.shift.each do |handler, args|
        handler.call(*args)
      end
    end
  end

  def handle_events
    return if @ios.empty?
    self.ready_ios_by_event.each do |event, ready_ios|
      ready_ios.each do |io|
        next unless @ios.has_key? io
        next unless handler = @ios[io][:callbacks][event]
        handler.call(io, *@ios[io][:args])
      end
    end
  end

  def ready_ios_by_event
    ready_ios = IO.select(self.ios_for(:read), self.ios_for(:write), @ios.keys, 0.01)
    ready_ios ||= [[],[],[]]
    { :read => ready_ios[0], :write => ready_ios[1], :error => ready_ios[2] }
  end

  def ios_for(event)
    @ios.select{|io, registry| registry[:events].include?(event) }.keys
  end

  def trim_events
    @ios.reject!{|io, registry| io.closed? }
  end

end
