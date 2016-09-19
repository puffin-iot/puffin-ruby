require File.expand_path('../../test_helper', __FILE__)

module Puffin
  class ApiResourceTest < Test::Unit::TestCase
    class NestedTestAPIResource < Puffin::APIResource
      # save_nested_resource :external_account
    end

    should "should raise an exception when not specifying the api token" do
      Puffin.api_token = nil
      assert_raises Puffin::AuthenticationError do
        Puffin::Device.create().refresh
      end
    end

    should "raise an exception when using a nil api token" do
      assert_raises TypeError do
        Puffin::Device.list({}, nil)
      end
      assert_raises TypeError do
        Puffin::Device.list({}, { :api_token => nil })
      end
    end
  end
end
