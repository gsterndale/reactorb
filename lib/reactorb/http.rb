require 'reactorb'
require 'reactorb/future'
require 'socket'

class Reactor
  module HTTP
    BYTE_SIZE = 100 # TODO determine performance characteristics

    def get(uri, &handler)
      io = TCPSocket.open(uri.host, uri.port)
      bytes = ''
      self.attach io, :write do |write_io|
        io.write "GET #{uri.path} HTTP/1.0\r\n\r\n"
        self.detach(write_io)
        self.attach io, :read do |read_io|
          if read_io.eof?
            read_io.close
            handler.call(bytes)
          else
            bytes << read_io.read_nonblock(BYTE_SIZE)
          end
        end
      end
    end

    def aget(uri)
      Future.start {|handler| self.get(uri, &handler) }
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
