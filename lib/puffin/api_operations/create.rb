module Puffin
  module APIOperations
    module Create
      def create(params={}, opts={})
        response, opts = request(:post, resource_url, params, opts)
        puts 1111111111111111111111111
        puts response
        # Util.convert_to_puffin_object(response, opts)
      end
    end
  end
end
