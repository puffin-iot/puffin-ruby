require File.expand_path('../test_helper', __FILE__)

class PuffinTest < Test::Unit::TestCase

  should "allow max_network_retries to be configured" do
    begin
      old = Puffin.max_network_retries
      Puffin.max_network_retries = 99
      assert_equal 99, Puffin.max_network_retries
    ensure
      Puffin.max_network_retries = old
    end
  end

  should "makes requests with the default Auth Bearer header" do
    Puffin.expects(:execute_request).with do |opts|
      opts[:headers]['Authorization'] == 'Bearer foo'
    end.returns(make_response(make_device))

    Puffin::Device.create()
  end

  should "makes requests with the customer Bearer header" do
    Puffin.api_token = "token"
    Puffin.expects(:execute_request).with do |opts|
      opts[:headers]['Authorization'] == 'Bearer token'
    end.returns(make_response(make_device))

    Puffin::Device.create()
  end
end
