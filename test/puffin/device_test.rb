require File.expand_path('../../test_helper', __FILE__)

module Puffin
  class DeviceTest < Test::Unit::TestCase
    should "list the devices as an array" do
      @mock.expects(:get).once.returns(make_response(make_device_array))
      d = Puffin::Device.list.data
      assert d.kind_of? Array
      assert d[0].kind_of? Puffin::Device
    end
  end
end
