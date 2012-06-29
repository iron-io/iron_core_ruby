require 'rest-client'
require 'rest'
require 'json'

require_relative 'iron_response_error'

module IronCore
  class Client
    attr_accessor :token
    attr_accessor :project_id

    attr_accessor :scheme
    attr_accessor :host
    attr_accessor :port
    attr_accessor :api_version
    attr_accessor :user_agent

    def initialize(product, options = {}, extra_options_list = [])
      @options_list = [:token, :project_id, :scheme, :host, :port, :api_version, :user_agent] + extra_options_list

      load_from_hash('params', options)
      load_from_config(product, options[:config_file] || options['config_file'])
      load_from_config(product, '.iron.json')
      load_from_config(product, 'iron.json')
      load_from_env('IRON_' + product.upcase)
      load_from_env('IRON')
      load_from_config(product, '~/.iron.json')

      # Should switch to net-http-persistent
      @rest = Rest::Client.new(:gem=>:rest_client)
    end

    def set_option(source, name, value)
      if send(name.to_s).nil? && (not value.nil?)
        IronCore::Logger.debug 'IronCore', "Setting #{name} to #{value} from #{source}"

        send(name.to_s + '=', value)
      end
    end

    def load_from_hash(source, hash)
      return if hash.nil?

      @options_list.each do |o|
        set_option(source, o, hash[o.to_sym] || hash[o.to_s])
      end
    end

    def load_from_env(prefix)
      @options_list.each do |o|
        set_option('environment variable', o, ENV[prefix + '_' + o.to_s.upcase])
      end
    end

    def load_from_config(product, config_file)
      return if config_file.nil?

      if File.exists?(File.expand_path(config_file))
        config = JSON.load(File.read(File.expand_path(config_file)))

        load_from_hash(config_file, config['iron_' + product])
        load_from_hash(config_file, config['iron'])
        load_from_hash(config_file, config)
      end
    end

    def options
      res = {}

      @options_list.each do |o|
        res[o.to_sym] = send(o.to_s)
      end

      res
    end

    def common_headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => "OAuth #{@token}",
        'User-Agent' => @user_agent
      }
    end

    def url
      "#{scheme}://#{host}:#{port}/#{api_version}/"
    end

    def get(method, params = {})
      request_hash = {}
      request_hash[:headers] = common_headers
      request_hash[:params] = params

      IronCore::Logger.debug 'IronCore', "GET #{url + method} with params='#{request_hash.to_s}'"

      @rest.get(url + method, request_hash)
    end

    def post(method, params = {})
      request_hash = {}
      request_hash[:headers] = common_headers
      request_hash[:body] = params.to_json

      IronCore::Logger.debug 'IronCore', "POST #{url + method} with params='#{request_hash.to_s}'" 

      @rest.post(url + method, request_hash)
    end

    def put(method, params={})
      request_hash = {}
      request_hash[:headers] = common_headers
      request_hash[:body] = params.to_json

      IronCore::Logger.debug 'IronCore', "PUT #{url + method} with params='#{request_hash.to_s}'"

      @rest.put(url + method, request_hash)
    end

    def delete(method, params = {})
      request_hash = {}
      request_hash[:headers] = common_headers
      request_hash[:params] = params

      IronCore::Logger.debug 'IronCore', "DELETE #{url + method} with params='#{request_hash.to_s}'"

      @rest.delete(url + method, request_hash)
    end

    # FIXME: retries support
    # FIXME: user agent support
    def post_file(method, file, params = {})
      request_hash = {}
      request_hash[:data] = params.to_json
      request_hash[:file] = file

      IronCore::Logger.debug 'IronCore', "POST #{url + method + "?oauth=" + @token} with params='#{request_hash.to_s}'"

      begin
        RestClient.post(url + method + "?oauth=#{@token}", request_hash)
      rescue RestClient::Unauthorized => e
        raise IronCore::IronResponseError.new(e.response)
      end
    end

    def parse_response(response, parse_json = true)
      IronCore::Logger.debug 'IronCore', "GOT #{response.code} with params='#{response.body}'"

      raise IronCore::IronResponseError.new(response) if response.code != 200

      # response in rest_client gem is a confusing object, of class String,
      # but with 'to_i' redefined to return response code and
      # 'body' defined to return itself
      body = String.new(response.body)

      return body unless parse_json
      JSON.parse(body)
    end
  end
end
