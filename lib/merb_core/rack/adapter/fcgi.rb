module Merb
  module Rack
    class FastCGI < Adapter
      def self.start_server(host=nil, port=nil)
        app = new
        Rack::Handler::FastCGI.run(app)
      end
    end
  end
end
