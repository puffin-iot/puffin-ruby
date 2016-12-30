require File.expand_path('../../test_helper', __FILE__)

module Puffin
  class MessageTest < Test::Unit::TestCase
    should "list the messgaes as an array" do
      @mock.expects(:get).once.returns(make_response(make_messages_array))
      o = Puffin::Message.list.data
      assert o.kind_of? Array
      assert o[0].kind_of? Puffin::Message
    end

    # should "create and return a device" do
    #   @mock.expects(:post).once.returns(make_response(make_operation))
    #   c = Puffin::Operation.create
    #   assert_equal "123", c.id
    # end

    should "fetch and return a message" do
      @mock.expects(:get).once.returns(make_response(make_message))
      c = Puffin::Message.fetch "123"
      assert_equal "123", c.id
    end
  end
end
