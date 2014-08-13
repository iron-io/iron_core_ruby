require 'keystone/v2_0/client'

module IronCore
  class KeystoneTokenProvider
    def initialize(client, options)
      @rest_client = client.dup
      @token = nil
      @server = options[:server]
      @tenant = options[:tenant]
      @username = options[:username]
      @password = options[:password]
    end

    def token
      if @token.nil?

        payload = {
            auth: {
                tenantName: @tenant,
                passwordCredentials: {
                    username: @username,
                    password: @password
                }
            }
        }
        response = post(@server + 'tokens', payload)
        result = JSON.parse(response.body)
        token_data = result['access']['token']

        @token = token_data['id']

      end

      puts "KEYSTONE TOKEN #{@token}"
      @token
      #"O7KrMTwmw997iq0KzL7v"
    end

    def post(path, params = {})
      request_hash = {}
      request_hash[:headers] = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      request_hash[:body] = params.to_json
      @rest_client.post(path, request_hash)
    end

  end
end