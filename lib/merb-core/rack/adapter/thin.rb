require 'thin'
# DOC: Ezra Zygmuntowicz FAILED
module Merb
  
  # DOC: Ezra Zygmuntowicz FAILED
  module Rack

    # DOC: Ezra Zygmuntowicz FAILED
    class Thin
      # start a Thin server on given host and port.

      # DOC: Ezra Zygmuntowicz FAILED
      def self.start(opts={})
        server = ::Thin::Server.new(opts[:host], opts[:port], opts[:app])
        server.silent = true
        server.start!
      end
    end
  end
end