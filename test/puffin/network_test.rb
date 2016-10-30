require File.expand_path('../../test_helper', __FILE__)

module Puffin
  class NetworkTest < Test::Unit::TestCase
    should "list the networks as an array" do
      @mock.expects(:get).once.returns(make_response(make_network_array))
      o = Puffin::Network.list.data
      assert o.kind_of? Array
      assert o[0].kind_of? Puffin::Network
    end

    should "create and return a network" do
      @mock.expects(:post).once.returns(make_response(make_network))
      c = Puffin::Network.create
      assert_equal "123", c.id
    end

    should "fetch and return a network" do
      @mock.expects(:get).once.returns(make_response(make_network))
      c = Puffin::Network.fetch "123"
      assert_equal "123", c.id
    end

    should "delete a network" do
      @mock.expects(:delete).once.returns(make_response(make_network({:deleted => true})))
      d = Puffin::Network.new "123"
      d.delete
      assert d.deleted
    end
  end
end
