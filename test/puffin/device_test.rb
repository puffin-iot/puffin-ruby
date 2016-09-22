require File.expand_path('../../test_helper', __FILE__)

module Puffin
  class DeviceTest < Test::Unit::TestCase
    should "list the devices as an array" do
      @mock.expects(:get).once.returns(make_response(make_device_array))
      d = Puffin::Device.list.data
      assert d.kind_of? Array
      assert d[0].kind_of? Puffin::Device
    end

    should "create and return a device" do
      @mock.expects(:post).once.returns(make_response(make_device))
      c = Puffin::Device.create
      assert_equal "123", c.id
    end

    should "fetch and return a device" do
      @mock.expects(:get).once.returns(make_response(make_device))
      c = Puffin::Device.fetch "123"
      assert_equal "123", c.id
    end

    should "save a device" do
      @mock.expects(:get).once.returns(make_response(make_device({:mnemonic => "foo"})))
      @mock.expects(:post).once.returns(make_response(make_device({:mnemonic => "bar"})))
      c = Puffin::Device.new("test_device").refresh
      assert_equal "foo", c.mnemonic
      c.mnemonic = "bar"
      c.save
      assert_equal "bar", c.mnemonic
    end

    should "delete a device" do
      @mock.expects(:delete).once.returns(make_response(make_device({:deleted => true})))
      d = Puffin::Device.new "123"
      d.delete
      assert d.deleted
    end

    should "update a device" do
      @mock.expects(:post).once.returns(make_response(make_device))
      c = Puffin::Device.create
      assert_equal "123", c.id

      @mock.expects(:patch).once.
        with("https://e83789d7.ngrok.io/v1/devices/1", nil, "metadata[foo]=bar").
        returns(make_response(make_device(metadata: {foo: 'bar'})))
      c = Puffin::Device.update("1", metadata: {foo: 'bar'})
      assert_equal('bar', c.metadata['foo'])
    end

  end
end
