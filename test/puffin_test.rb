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

  should "makes requests with the Puffin-Account header" do
    response = make_account(
      email: "test@puffin.ly"
    )
    Puffin.puffin_account = 'auks_1234'

    Puffin.expects(:execute_request).with(
      has_entry(:headers, has_entry('Puffin-Account', 'auks_1234')),
    ).returns(make_response(response))

    Puffin.request(:post, '/v1/account', 'sk_live12334566')
  end
end
