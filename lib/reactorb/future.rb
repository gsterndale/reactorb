require 'delegate'
require 'fiber'

class Reactor
  class Future < Delegator
    def self.start(&block)
      Future.new.tap do |future|
        Fiber.new do
          f = Fiber.current
          handler = -> (delegate_obj) { f.resume(delegate_obj) }
          block.call(handler)
          # Yield control back to context that resume()d current fiber (i.e. Reactor#run()'s Fiber).
          # Then Fiber.yield will return the delegate object once this fiber is resume()d by handler
          future.__setobj__ Fiber.yield
        end.resume
      end
    end

    def initialize(obj = nil)
      super
      @obj_set         = !!obj
      @delegate_sd_obj = obj
    end

    def __getobj__
      if !@obj_set
        @fiber = Fiber.current
        Fiber.yield
      end
      @delegate_sd_obj
    end

    def __setobj__(obj)
      @delegate_sd_obj = obj
      @obj_set         = true
      @fiber.resume if @fiber
      @delegate_sd_obj
    end
  end
end
