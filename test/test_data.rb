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
  end
end
