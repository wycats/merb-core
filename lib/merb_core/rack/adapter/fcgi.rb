module Merb
  module Rack
    class FastCGI < Adapter
      class << self
        def start_server(host=nil, port=nil)
          Rack::Handler::FastCGI.run(self)
        end
      end
    end
  end
end
