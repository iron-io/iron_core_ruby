require 'logger'

module IronCore
  module Logger
    def self.logger
      unless @logger
        @logger = ::Logger.new(STDOUT)
        @logger.level = ::Logger::INFO
      end

      @logger
    end

    def self.logger=(logger)
      @logger = logger
    end

    def self.fatal(product, msg)
      self.logger.fatal(product) { msg }
    end

    def self.error(product, msg)
      self.logger.error(product) { msg }
    end

    def self.warn(product, msg)
      self.logger.warn(product) { msg }
    end

    def self.info(product, msg)
      self.logger.info(product) { msg }
    end

    def self.debug(product, msg)
      self.logger.debug(product) { msg }
    end
  end
end
