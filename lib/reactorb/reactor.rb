require 'reactorb/callback_registry'

class Reactor

  attr_reader :timer_registry
  attr_reader :io_registry
  IO_EVENTS  = [:read, :write, :error].freeze
  IO_TIMEOUT = 0.01

  def self.now
    Time.now.to_i
  end

  def initialize
    @running = false
    @timer_registry = CallbackRegistry.new
    @io_registry = IOCallbackRegistry.new
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
    self.call_events
    self.call_timers
    @tick_time = nil
  end

  def in(seconds, *args, &callback)
    self.at(self.class.now + seconds, *args, &callback)
  end

  def at(time, *args, &callback)
    @timer_registry[time.to_i] << [callback, args]
  end

  def attach(io, *args, &callback)
    events = IO_EVENTS & args # intersection
    args = args - events
    events.each do |event|
      @io_registry[io][event] = [callback, args]
    end
  end

  def detach(io)
    @io_registry.delete io
  end

  def empty?
    @io_registry.empty? && @timer_registry.empty?
  end

protected

  attr_reader :tick_time

  def call_timers
    while @timer_registry.any? && @timer_registry.first_key <= self.tick_time
      @timer_registry.shift.each do |callback, args|
        callback.call(*args)
      end
    end
  end

  def call_events
    @io_registry.reject_closed
    return if @io_registry.empty?
    self.ready_ios_by_event.each do |event, ios|
      ios.each do |io|
        callback, args = @io_registry[io][event]
        next unless callback
        callback.call(io, *args)
      end
    end
  end

  def ready_ios_by_event
    ios = IO.select(@io_registry.ios_for(:read), @io_registry.ios_for(:write), @io_registry.ios_for(:error), IO_TIMEOUT)
    return {} unless ios
    { :read => ios[0], :write => ios[1], :error => ios[2] }
  end

  class IOCallbackRegistry < Hash
    def initialize(*args, &blk)
      blk ||= proc {|registries,io| registries[io] = CallbackRegistry.new }
      super *args, &blk
    end
    alias_method :io?, :key?
    alias_method :ios, :keys
    def ios_for(event)
      self.select{|io, registry| registry.key?(event) }.keys
    end
    def reject_closed
      self.reject!{|io, registry| io.closed? }
    end
  end

end

