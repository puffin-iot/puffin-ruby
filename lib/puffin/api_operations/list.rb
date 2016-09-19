module Puffin
  module APIOperations
    module List
      def list(filters={}, opts={})
        opts = Util.normalize_opts(opts)

        response, opts = request(:get, resource_url, filters, opts)
        obj = ListObject.construct_from(response, opts)

        # obj.filters = filters.dup
        # obj.filters.delete(:ending_before)
        # obj.filters.delete(:starting_after)

        obj
      end
    end
  end
end
