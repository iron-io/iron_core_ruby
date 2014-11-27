module IronCore
  class KeystoneTokenProvider
    def initialize(client, options)
      @rest_client = client.dup
      @token = options[:tenant_token] # Way to bypass fetching a token from keystone api
      @server = options[:server]
      @tenant = options[:tenant]
      @username = options[:username]
      @password = options[:password]
      @user_token = options[:token]
    end

    def token
      if @token.nil? || (@local_expires_at && (Time.now - @local_expires_at > -10))
        payload = {
          auth: {
            tenantId: @tenant,
          }
        }
        if @username.to_s != ''
          payload[:auth][:passwordCredentials] = {
            username: @username,
            password: @password
          }
        elsif @user_token.to_s != ''
          payload[:auth][:token] = {id: @user_token}
        end

        response = post(@server + 'tokens', payload)
        result = JSON.parse(response.body)
        token_data = result['access']['token']

        issued_at = Time.parse(token_data['issued_at'] + " UTC")
        expires = Time.parse(token_data['expires'] + " UTC")
        duration = (expires - issued_at).to_i

        @local_expires_at = Time.now + duration
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