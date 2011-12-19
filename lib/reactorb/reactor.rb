class Reactor

  attr_reader :timers

  def initialize()
    @running = false
    @timers = ShiftableHash.new
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

  def first_tick()
  end

  def tick()
    self.call_timers()
  end

  def at(time_or_number, *args, &block)
    @timers[time_or_number.to_i] = [block, args]
  end

  def call_timers
    now = Time.now.to_i
    while @timers.any? && @timers.first_key <= now
      block, args = @timers.shift
      block.call(*args)
    end
  end

  def empty?
    @timers.empty?
  end

end

class ShiftableHash < Hash
  def first_key
    self.keys.sort.first
  end
  def shift
    if key = self.first_key
      self.delete key
    end
  end
  def shift_pair
    if key = self.first_key
      [ key, self.delete(key) ]
    end
  end
end
