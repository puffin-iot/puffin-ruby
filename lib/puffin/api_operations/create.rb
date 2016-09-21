module Puffin
  module APIOperations
    module Create
      def create(params={}, opts={})
        puts params, opts, resource_url
        response, opts = request(:post, resource_url, params, opts)
        puts response
        a = Util.convert_to_puffin_object(response, opts)
        puts a
        a
      end
    end
  end
end
