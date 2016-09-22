module Puffin
  class Device < APIResource
    extend Puffin::APIOperations::Create
    extend Puffin::APIOperations::List
    include Puffin::APIOperations::Delete
    include Puffin::APIOperations::Save

    def reset(params = {}, opts = {})
      response, opts = request(:post, reset_url, params, opts)
      initialize_from(response, opts)
    end

    private

    def reset_url
      resource_url + '/reset'
    end
  end
end

