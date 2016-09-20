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

    should "return an array of objects" do
      response = make_response(make_device_array)
      puts 11111111111111111111111111111111111111111111111
      puts response.inspect
      puts 11111111111111111111111111111
      @mock.expects(:get).with("#{Stripe.api_base}/v1/charges?customer=test+customer", nil, nil).returns(response)
      # charges = Stripe::Charge.list(:customer => 'test customer').data
      # assert charges.kind_of? Array
    end

  end
end
