# Some of this helper logic came from Stripe's ruby client test
module Puffin
  module TestData
    def make_response(body, code=200)
      body = JSON.generate(body) if !(body.kind_of? String)
      m = mock
      m.instance_variable_set('@stripe_values', {
        :body => body,
        :code => code,
        :headers => {},
      })
      def m.body; @stripe_values[:body]; end
      def m.code; @stripe_values[:code]; end
      def m.headers; @stripe_values[:headers]; end
      m
    end

    def make_account(params={})
      {
        :email => "test@puffin.ly",
      }.merge(params)
    end

    def mac
      (1..6).map{"%0.2X"%rand(256)}.join("-")
    end

    def make_device(params={})
      id = params[:id] || '123'
      {
        id: id,
        mac: mac,
        description: 'My Fab Device',
        network_id: 1,
        project_id: 2,
        private_token: SecureRandom.hex,
        public_token: SecureRandom.hex,
        sync_user: SecureRandom.hex(5),
        sync_pass: SecureRandom.hex(5),
        sync_topic: SecureRandom.hex(5),
        sync_key: SecureRandom.hex(5),
        sync_status_topic: SecureRandom.hex(5),
        created_at: Time.now.to_i,
        updated_at: Time.now.to_i,
        region: 'eu-west',
        :metadata => {},
      }.merge(params)
    end

    def make_device_array
      {
        :data => [make_device, make_device],
        :object => 'device',
        :resource_url => '/v1/devices'
      }
    end
  end
end
