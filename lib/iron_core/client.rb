require 'rest'
require 'json'

require_relative 'response_error'

module IronCore
  class Client
    attr_accessor :headers
    attr_accessor :content_type

    def initialize(company, product, options = {}, default_options = {}, extra_options_list = [])
      @options_list = [:scheme, :host, :port, :user_agent, :http_gem] + extra_options_list

      metaclass = class << self
        self
      end

      @options_list.each do |option|
        metaclass.send(:define_method, option.to_s) do
          instance_variable_get('@' + option.to_s)
        end

        metaclass.send(:define_method, option.to_s + '=') do |value|
          instance_variable_set('@' + option.to_s, value)
        end
      end

      load_from_hash('params', options)
      load_from_config(company, product, options[:config] || options['config'])
      load_from_config(company, product, ENV[company.upcase + '_' + product.upcase + '_CONFIG'])
      load_from_config(company, product, ENV[company.upcase + '_CONFIG'])
      load_from_env(company.upcase + '_' + product.upcase)
      load_from_env(company.upcase)
      load_from_config(company, product, ".#{company}.json")
      load_from_config(company, product, "#{company}.json")
      load_from_config(company, product, "~/.#{company}.json")
      load_from_hash('defaults', default_options)
      load_from_hash('defaults', {:user_agent => 'iron_core_ruby-' + IronCore.version})

      @headers = {}
      @content_type = 'application/json'

      @rest = Rest::Client.new(:gem => @http_gem.to_sym)
    end

    def set_option(source, name, value)
      if send(name.to_s).nil? && (not value.nil?)
        IronCore::Logger.debug 'IronCore', "Setting #{name} to '#{value}' from #{source}"

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

    def load_from_config(company, product, config_file)
      return if config_file.nil?

      if File.exists?(File.expand_path(config_file))
        config = JSON.load(File.read(File.expand_path(config_file)))

        load_from_hash(config_file, config["#{company}_#{product}"])
        load_from_hash(config_file, config[company])
        load_from_hash(config_file, config)
      end
    end

    def options(return_strings = false)
      res = {}

      @options_list.each do |option|
        res[return_strings ? option.to_s : option.to_sym] = send(option.to_s)
      end

      res
    end

    def common_headers
      {'User-Agent' => @user_agent}
    end

    def url
      "#{scheme}://#{host}:#{port}/"
    end

    def get(method, params = {})
      request_hash = {}
      request_hash[:headers] = common_headers.merge(@headers)
      request_hash[:params] = params

      IronCore::Logger.debug 'IronCore', "GET #{url + method} with params='#{request_hash.to_s}'"

      @rest.get(url + method, request_hash)
    end

    def post(method, params = {})
      request_hash = {}
      request_hash[:headers] = common_headers.merge(@headers).merge({'Content-Type' => @content_type})
      request_hash[:body] = params.to_json

      IronCore::Logger.debug 'IronCore', "POST #{url + method} with params='#{request_hash.to_s}'" 

      @rest.post(url + method, request_hash)
    end

    def put(method, params={})
      request_hash = {}
      request_hash[:headers] = common_headers.merge(@headers).merge({'Content-Type' => @content_type})
      request_hash[:body] = params.to_json

      IronCore::Logger.debug 'IronCore', "PUT #{url + method} with params='#{request_hash.to_s}'"

      @rest.put(url + method, request_hash)
    end

    def delete(method, params = {})
      request_hash = {}
      request_hash[:headers] = common_headers.merge(@headers)
      request_hash[:params] = params

      IronCore::Logger.debug 'IronCore', "DELETE #{url + method} with params='#{request_hash.to_s}'"

      @rest.delete(url + method, request_hash)
    end

    def post_file(method, file_field, file, params_field, params = {})
      request_hash = {}
      request_hash[:headers] = common_headers.merge(@headers)
      request_hash[:body] = {params_field => params.to_json, file_field => file}

      IronCore::Logger.debug 'IronCore', "POST #{url + method} with params='#{request_hash.to_s}'"

      @rest.post_file(url + method, request_hash)
    end

    def parse_response(response, parse_json = true)
      IronCore::Logger.debug 'IronCore', "GOT #{response.code} with params='#{response.body}'"

      raise IronCore::ResponseError.new(response) if response.code != 200

      body = String.new(response.body)

      return body unless parse_json

      JSON.parse(body)
    end
  end
end
