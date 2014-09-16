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
      if @token.nil? || (Time.now - @local_expirest_at > -10)
        payload = {
            auth: {
                tenantId: @tenant,
                passwordCredentials: {
                    username: @username,
                    password: @password
                }
            }
        }

        response = post(@server + 'tokens', payload)
        result = JSON.parse(response.body)
        token_data = result['access']['token']

        issued_at = Time.parse(token_data['issued_at'] + " UTC")
        expires = Time.parse(token_data['expires'] + " UTC")
        duration = (expires - issued_at).to_i

        @local_expirest_at = Time.now + duration
        @token = token_data['id']
      end

      @token
    end

    def post(path, params = {})
      request_hash = {}
      request_hash[:headers] = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      request_hash[:body] = params.to_json
      @rest_client.post(path, request_hash)
    end
  end
end