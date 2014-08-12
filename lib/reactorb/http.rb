require 'reactorb'
require 'reactorb/future'
require 'socket'

class Reactor
  module HTTP
    BYTE_SIZE = 100 # TODO determine performance characteristics

    %i(get put post delete head).each do |verb|
      define_method verb, -> (uri, &handler) do
        request(verb.to_s.upcase, uri, &handler)
      end

      define_method "a#{verb}".to_sym do |uri|
        Future.start do |handler|
          request(verb.to_s.upcase, uri, &handler)
        end
      end
    end

    def request(verb, uri, &handler)
      io = TCPSocket.open(uri.host, uri.port)
      bytes = ''
      self.attach io, :write do |write_io|
        io.write "#{verb.upcase} #{uri.path} HTTP/1.0\r\n\r\n"
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
  end
end
