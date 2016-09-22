require 'puffin'
require 'test/unit'
require 'mocha/setup'
# require 'stringio'
require 'shoulda/context'
require File.expand_path('../test_data', __FILE__)

module Puffin
  @mock_rest_client = nil

  def self.mock_rest_client=(mock_client)
    @mock_rest_client = mock_client
  end

  class << self
    remove_method :execute_request
  end

  def self.execute_request(opts)
    get_params = (opts[:headers] || {})[:params]
    post_params = opts[:payload]
    case opts[:method]
    when :get then @mock_rest_client.get opts[:url], get_params, post_params
    when :post then @mock_rest_client.post opts[:url], get_params, post_params
    when :patch then @mock_rest_client.patch opts[:url], get_params, post_params
    when :delete then @mock_rest_client.delete opts[:url], get_params, post_params
    end
  end
end

class Test::Unit::TestCase
  include Puffin::TestData
  include Mocha

  setup do
    @mock = mock
    Puffin.mock_rest_client = @mock
    Puffin.api_token = "foo"
  end

  teardown do
    Puffin.mock_rest_client = nil
    Puffin.api_token = nil
  end
end
