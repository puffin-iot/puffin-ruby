module Puffin
  class Operation < APIResource
    extend Puffin::APIOperations::Create
    extend Puffin::APIOperations::List
    # include Puffin::APIOperations::Save

    def cancel(params = {}, opts = {})
      response, opts = request(:post, cancel_url, params, opts)
      initialize_from(response, opts)
    end

    private

    def cancel_url
      resource_url + '/cancel'
    end
  end
end

