require 'reactorb'
require 'socket'
require 'fiber'
require 'delegate'

class Reactor
  module HTTP
    def get(uri, &handler)
      host = uri.host
      port = uri.port
      io = TCPSocket.open(host, port)
      bytes = ''
      self.attach io, :write do |write_io|
        io.write "GET #{uri.path} HTTP/1.0\r\n\r\n"
        self.detach(write_io)
        self.attach io, :read do |read_io|
          if read_io.eof?
            read_io.close
            handler.call(bytes)
          else
            # TODO determine performance characteristics
            # bytes << read_io.read_nonblock(1448)
            chunk = read_io.read(20)
            bytes << chunk
          end
        end
      end
    end

    class ADelegator < Delegator
      def self.future(&block)
        delegator = ADelegator.new
        Fiber.new do
          f = Fiber.current
          callback = -> (result) { f.resume(result) }
          block.call(callback)
          # yield control back to context that resume()d
          # current fiber (Reactor#run() Fiber)
          # Then Fiber.yield will return the response once
          # this fiber is resume()d
          delegator.__setobj__ Fiber.yield
        end.resume
        delegator
      end

      def initialize(obj=nil)
        super
        @obj_set         = !!obj
        @delegate_sd_obj = obj
      end

      def __getobj__
        if !@obj_set
          @fiber = Fiber.current
          # yield control back to context that
          #   resume()d current fiber (#aget() Fiber)
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

    # Fiber gymnastics
    def aget(uri)
      ADelegator.future do |callback|
        self.get(uri) {|response| callback.call(response) }
      end
    end


    def head(uri, &handler)
    end
    def delete(uri, &handler)
    end
    def put(uri, data, &handler)
    end
    def post(uri, data, &handler)
    end
  end
end

