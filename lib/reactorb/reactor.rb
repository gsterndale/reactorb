require 'reactorb/callback_registry'

class Reactor

  attr_reader :timers

  def initialize()
    @running = false
    @timers = CallbackRegistry.new
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
    self.call_timers
    @tick_time = nil
  end

  def at(time_or_number, *args, &block)
    @timers[time_or_number.to_i] << [block, args]
  end

  def call_timers
    while @timers.any? && @timers.first_key <= self.tick_time
      @timers.shift.each do |block, args|
        block.call(*args)
      end
    end
  end

  def empty?
    @timers.empty?
  end

  def self.now
    Time.now.to_i
  end

protected

  attr_reader :tick_time

end
