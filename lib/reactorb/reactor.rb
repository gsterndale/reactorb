class Reactor

  attr_reader :timer_dispatcher
  attr_reader :event_dispatcher
  IO_EVENTS  = [:read, :write, :error].freeze
  IO_TIMEOUT = 0.01

  def self.run(&block)
    self.new.run(&block)
  end

  def self.now
    Time.now.to_i
  end

  def initialize
    @running = false
    @timer_dispatcher = TimerDispatcher.new
    @event_dispatcher = IODispatcher.new
  end

  def running?
    !!@running
  end

  def run
    @running = true
    Fiber.new do
      yield self if block_given?
    end.resume
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
    self.dispatch_events
    self.dispatch_timers
    @tick_time = nil
  end

  def in(seconds, *args, &handler)
    self.at(self.class.now + seconds, *args, &handler)
  end

  def at(time, *args, &handler)
    @timer_dispatcher.register(time.to_i, args, handler)
  end

  def attach(io, *args, &handler)
    events = IO_EVENTS & args # intersection
    args = args - events
    @event_dispatcher.register(io, events, args, handler)
  end

  def detach(io)
    @event_dispatcher.unregister io
  end

  def empty?
    @event_dispatcher.empty? && @timer_dispatcher.empty?
  end

protected

  def dispatch_timers
    @timer_dispatcher.dispatch(@tick_time)
  end

  def dispatch_events
    @event_dispatcher.unregister_closed
    return if @event_dispatcher.empty?
    self.ready_ios_by_event.each do |event, ios|
      ios.each do |io|
        @event_dispatcher.dispatch(io, event)
      end
    end
  end

  def ready_ios_by_event
    ios = IO.select(
      @event_dispatcher.registered_for(:read),
      @event_dispatcher.registered_for(:write),
      @event_dispatcher.registered_for(:error),
      IO_TIMEOUT
    )
    return {} unless ios
    { :read => ios[0], :write => ios[1], :error => ios[2] }
  end

  class TimerDispatcher < Hash
    def initialize(*args, &blk)
      blk ||= proc {|registries,io| registries[io] = [] }
      super *args, &blk
    end

    def register(times, args, handler)
      Array(times).each do |time|
        self[time] << [handler, args]
      end
    end

    def dispatch(time)
      while self.any? && first_key <= time
        shift.each do |handler, args|
          handler.call(*args)
        end
      end
    end

    private

    def first_key
      self.keys.sort.first
    end

    def shift
      if key = first_key
        self.delete key
      end
    end
  end

  class IODispatcher < Hash
    def initialize(*args, &blk)
      blk ||= proc {|registries,io| registries[io] = {} }
      super *args, &blk
    end
    alias_method :io?, :key?
    alias_method :ios, :keys

    def register(io, events, args, handler)
      Array(events).each do |event|
        self[io][event] = [handler, args]
      end
    end

    def unregister(io)
      self.delete io
    end

    def dispatch(io, event)
      handler, args = self[io][event]
      handler.call(io, *args) if handler
    end

    def registered_for(event)
      self.select{|io, registry| registry.key?(event) }.keys
    end

    def unregister_closed
      self.reject!{|io, registry| io.closed? }
    end
  end

end

