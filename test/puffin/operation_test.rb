require File.expand_path('../../test_helper', __FILE__)

module Puffin
  class OperationTest < Test::Unit::TestCase
    should "list the operations as an array" do
      @mock.expects(:get).once.returns(make_response(make_operation_array))
      o = Puffin::Operation.list.data
      assert o.kind_of? Array
      assert o[0].kind_of? Puffin::Operation
    end

    should "create and return a device" do
      @mock.expects(:post).once.returns(make_response(make_operation))
      c = Puffin::Operation.create
      assert_equal "123", c.id
    end

    should "fetch and return a operation" do
      @mock.expects(:get).once.returns(make_response(make_operation))
      c = Puffin::Operation.fetch "123"
      assert_equal "123", c.id
    end

    # should "save a device" do
    #   @mock.expects(:get).once.returns(make_response(make_device({:mnemonic => "foo"})))
    #   @mock.expects(:post).once.returns(make_response(make_device({:mnemonic => "bar"})))
    #   c = Puffin::Device.new("test_device").refresh
    #   assert_equal "foo", c.mnemonic
    #   c.mnemonic = "bar"
    #   c.save
    #   assert_equal "bar", c.mnemonic
    # end

    # should "delete a device" do
    #   @mock.expects(:delete).once.returns(make_response(make_device({:deleted => true})))
    #   d = Puffin::Device.new "123"
    #   d.delete
    #   assert d.deleted
    # end

    # should "update a device" do
    #   @mock.expects(:post).once.returns(make_response(make_device))
    #   c = Puffin::Device.create
    #   assert_equal "123", c.id

    #   @mock.expects(:patch).once.
    #     with("#{Puffin.api_base}/v1/devices/1", nil, "metadata[foo]=bar").
    #     returns(make_response(make_device(metadata: {foo: 'bar'})))
    #   c = Puffin::Device.update("1", metadata: {foo: 'bar'})
    #   assert_equal('bar', c.metadata['foo'])
    # end

    should "cancel a operation" do
      data = make_operation
      o = Puffin::Operation.construct_from(make_operation)
      @mock.expects(:get).never
      @mock.expects(:post).once.
        with("#{Puffin.api_base}/v1/operations/#{o.id}/cancel", nil, '').
        returns(make_response(data))
        o = o.cancel
      assert o.is_a?(Puffin::Operation)
    end
  end
end
