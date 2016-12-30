# Some of this helper logic came from puffin's ruby client test
module Puffin
  module TestData
    def make_response(body, code=200)
      body = JSON.generate(body) if !(body.kind_of? String)
      m = mock
      m.instance_variable_set('@puffin_values', {
        :body => body,
        :code => code,
        :headers => {},
      })
      def m.body; @puffin_values[:body]; end
      def m.code; @puffin_values[:code]; end
      def m.headers; @puffin_values[:headers]; end
      m
    end

    def make_account(params={})
      {
        :email => "test@puffin.ly",
      }.merge(params)
    end

    def generate_mac
      (1..6).map{"%0.2X"%rand(256)}.join("-")
    end

    def make_device(params={})
      id = params[:id] || '123'
      {
        id: id,
        mac: generate_mac,
        description: 'My Fab Device',
        network_id: 1,
        project_id: 2,
        private_token: SecureRandom.hex,
        public_token: SecureRandom.hex,
        object: 'device',
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

    def make_network(params={})
      id = params[:id] || '123'
      {
        id: id,
        object: 'network',
        status: 'DONE'
      }.merge(params)
    end

    def make_network_array
      {
        :data => [make_network, make_network],
        :object => 'network',
        :resource_url => '/v1/networks'
      }
    end

    def make_operation(params={})
      id = params[:id] || '123'
      {
        id: id,
        object: 'operation',
        status: 'DONE'
      }.merge(params)
    end

    def make_operation_array
      {
        :data => [make_operation, make_operation],
        :object => 'operation',
        :resource_url => '/v1/operations'
      }
    end

    def make_message(params={})
      id = params[:id] || '123'
      {
        id: id,
        object: 'message',
        msg: 'DONE'
      }.merge(params)
    end

    def make_messages_array
      {
        :data => [make_message, make_message],
        :object => 'message',
        :resource_url => '/v1/messages'
      }
    end
  end
end
