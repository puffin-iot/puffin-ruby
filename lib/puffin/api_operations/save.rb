module Puffin
  module APIOperations
    module Save
      module ClassMethods
        def update(id, params={}, opts={})
          response, opts = request(:post, "#{resource_url}/#{id}", params, opts)
          Util.convert_to_stripe_object(response, opts)
        end
      end

      def save(params={}, opts={})
        update_attributes(params)
        params = params.reject { |k, _| respond_to?(k) }
        values = self.serialize_params(self).merge(params)
        values.delete(:id)
        response, opts = request(:post, save_url, values, opts)
        initialize_from(response, opts)

        self
      end

      def self.included(base)
      end

      private

      def save_url
      end
    end
  end
end
