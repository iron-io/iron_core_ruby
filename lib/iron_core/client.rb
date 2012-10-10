require 'rest'
require 'json'

require_relative 'response_error'

module IronCore
  class Client
    attr_accessor :content_type
    attr_accessor :env

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

      @env = options[:env] || options['env']
      @env ||= ENV[company.upcase + '_' + product.upcase + '_ENV'] || ENV[company.upcase + '_ENV']

      IronCore::Logger.info 'IronCore', "Setting env to '#{@env}'" unless @env.nil?

      load_from_hash('params', options)

      load_from_config(company, product, options[:config] || options['config'])

      load_from_config(company, product, ENV[company.upcase + '_' + product.upcase + '_CONFIG'])
      load_from_config(company, product, ENV[company.upcase + '_CONFIG'])

      load_from_env(company.upcase + '_' + product.upcase)
      load_from_env(company.upcase)

      suffixes = []

      unless @env.nil?
        suffixes << "-#{@env}"
        suffixes << "_#{@env}"
      end
      
      suffixes << ''

      suffixes.each do |suffix|
        ['.json'].each do |ext|
          ["#{company}-#{product}", "#{company}_#{product}", company].each do |config_base|
            load_from_config(company, product, "#{Dir.pwd}/#{config_base}#{suffix}#{ext}")
            load_from_config(company, product, "#{Dir.pwd}/.#{config_base}#{suffix}#{ext}")
            load_from_config(company, product, "#{Dir.pwd}/config/#{config_base}#{suffix}#{ext}")
            load_from_config(company, product, "#{Dir.pwd}/config/.#{config_base}#{suffix}#{ext}")
            load_from_config(company, product, "~/#{config_base}#{suffix}#{ext}")
            load_from_config(company, product, "~/.#{config_base}#{suffix}#{ext}")
          end
        end
      end

      load_from_hash('defaults', default_options)
      load_from_hash('defaults', {:user_agent => 'iron_core_ruby-' + IronCore.version})

      @content_type = 'application/json'

      http_gem = @http_gem.nil? ? nil : @http_gem.to_sym

      @rest = Rest::Client.new(:gem => http_gem)
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

    def get_sub_hash(hash, subs)
      return nil if hash.nil?

      subs.each do |sub|
        return nil if hash[sub].nil?

        hash = hash[sub]
      end

      hash
    end

    def load_from_config(company, product, config_file)
      return if config_file.nil?

      if File.exists?(File.expand_path(config_file))
        config_data = '{}'

        begin
          config_data = File.read(File.expand_path(config_file))
        rescue
          return
        end

        config = JSON.parse(config_data)

        unless @env.nil?
          load_from_hash(config_file, get_sub_hash(config, [@env, "#{company}_#{product}"]))
          load_from_hash(config_file, get_sub_hash(config, [@env, company, product]))
          load_from_hash(config_file, get_sub_hash(config, [@env, product]))
          load_from_hash(config_file, get_sub_hash(config, [@env, company]))

          load_from_hash(config_file, get_sub_hash(config, ["#{company}_#{product}", @env]))
          load_from_hash(config_file, get_sub_hash(config, [company, product, @env]))
          load_from_hash(config_file, get_sub_hash(config, [product, @env]))
          load_from_hash(config_file, get_sub_hash(config, [company, @env]))

          load_from_hash(config_file, get_sub_hash(config, [@env]))
        end

        load_from_hash(config_file, get_sub_hash(config, ["#{company}_#{product}"]))
        load_from_hash(config_file, get_sub_hash(config, [company, product]))
        load_from_hash(config_file, get_sub_hash(config, [product]))
        load_from_hash(config_file, get_sub_hash(config, [company]))
        load_from_hash(config_file, get_sub_hash(config, []))
      end
    end

    def options(return_strings = false)
      res = {}

      @options_list.each do |option|
        res[return_strings ? option.to_s : option.to_sym] = send(option.to_s)
      end

      res
    end

    def headers
      {'User-Agent' => @user_agent}
    end

    def base_url
      "#{scheme}://#{host}:#{port}/"
    end

    def url(method)
      base_url + method
    end

    def get(method, params = {})
      request_hash = {}
      request_hash[:headers] = headers
      request_hash[:params] = params

      IronCore::Logger.debug 'IronCore', "GET #{url(method)} with params='#{request_hash.to_s}'"

      @rest.get(url(method), request_hash)
    end

    def post(method, params = {})
      request_hash = {}
      request_hash[:headers] = headers.merge({'Content-Type' => @content_type})
      request_hash[:body] = params.to_json

      IronCore::Logger.debug 'IronCore', "POST #{base_url + method} with params='#{request_hash.to_s}'"

      @rest.post(base_url + method, request_hash)
    end

    def put(method, params={})
      request_hash = {}
      request_hash[:headers] = headers.merge({'Content-Type' => @content_type})
      request_hash[:body] = params.to_json

      IronCore::Logger.debug 'IronCore', "PUT #{base_url + method} with params='#{request_hash.to_s}'"

      @rest.put(base_url + method, request_hash)
    end

    def delete(method, params = {})
      request_hash = {}
      request_hash[:headers] = headers
      request_hash[:params] = params

      IronCore::Logger.debug 'IronCore', "DELETE #{base_url + method} with params='#{request_hash.to_s}'"

      @rest.delete(base_url + method, request_hash)
    end

    def post_file(method, file_field, file, params_field, params = {})
      request_hash = {}
      request_hash[:headers] = headers
      request_hash[:body] = {params_field => params.to_json, file_field => file}

      IronCore::Logger.debug 'IronCore', "POST #{base_url + method} with params='#{request_hash.to_s}'"

      @rest.post_file(base_url + method, request_hash)
    end

    def parse_response(response, parse_json = true)
      IronCore::Logger.debug 'IronCore', "GOT #{response.code} with params='#{response.body}'"

      raise IronCore::ResponseError.new(response) if response.code != 200

      body = String.new(response.body)

      return body unless parse_json

      JSON.parse(body)
    end

    def check_id(id, name = 'id', length = 24)
      if (not id.is_a?(String)) || id.length != length
        IronCore::Logger.error 'IronCore', "Expecting #{length} symbol #{name} string", IronCore::Error
      end
    end
  end
end
