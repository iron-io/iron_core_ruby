require 'rest-client'
require 'rest'
require 'json'

require_relative 'iron_error'

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

      load_from_hash(options)
      load_from_config(product, options[:config_file] || options['config_file'])
      load_from_config(product, 'iron.json')
      load_from_env('IRON_' + product.upcase)
      load_from_env('IRON')
      load_from_config(product, '~/.iron.json')

      @rest = Rest::Client.new
    end

    def set_option(name, value)
      if send(name.to_s).nil?
        send(name.to_s + '=', value)
      end
    end

    def load_from_hash(hash)
      return if hash.nil?

      @options_list.each do |o|
        set_option(o, hash[o.to_sym] || hash[o.to_s])
      end
    end

    def load_from_env(prefix)
      @options_list.each do |o|
        set_option(o, ENV[prefix + '_' + o.to_s.upcase])
      end
    end

    def load_from_config(product, config_file)
      return if config_file.nil?

      if File.exists?(File.expand_path(config_file))
        config = JSON.load(File.read(File.expand_path(config_file)))

        load_from_hash(config['iron_' + product])
        load_from_hash(config['iron'])
        load_from_hash(config)
      end
    end

    def options
      res = {}

      @options_list.each do |o|
        res[o.to_sym] = send(o.to_s)
      end

      res
    end

    def common_request_hash
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
      request_hash[:headers] = common_request_hash
      request_hash[:params] = params

      IronCore::Logger.debug 'IronCore', "GET #{url + method} with params='#{request_hash.to_s}'"

      @rest.get(url + method, request_hash)
    end

    def post(method, params = {})
      request_hash = {}
      request_hash[:headers] = common_request_hash
      request_hash[:body] = params.to_json

      IronCore::Logger.debug 'IronCore', "POST #{url + method} with params='#{request_hash.to_s}'" 

      @rest.post(url + method, request_hash)
    end

    def delete(method, params = {})
      request_hash = {}
      request_hash[:headers] = common_request_hash
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

      RestClient.post(url + method + "?oauth=#{@token}", request_hash) 
    end

    def parse_response(response, parse_json = true)
      IronCore::Logger.debug 'IronCore', "GOT #{response.code} with params='#{response.body}'"

      raise IronCore::IronError.new(response.body) if response.code != 200

      return response.body unless parse_json
      JSON.parse(response.body)
    end
  end
end
