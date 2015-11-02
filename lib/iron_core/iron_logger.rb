require 'logger'

module IronCore
  module Logger
    def self.logger
      unless defined?(@logger) && @logger
        @logger = ::Logger.new(STDOUT)
        @logger.level = ::Logger::INFO
      end

      @logger
    end

    def self.logger=(logger)
      @logger = logger
    end

    def self.fatal(product, msg, exception_class = nil)
      self.logger.fatal(product) { msg }

      self.raise_exception(msg, exception_class)
    end

    def self.error(product, msg, exception_class = nil)
      self.logger.error(product) { msg }

      self.raise_exception(msg, exception_class)
    end

    def self.warn(product, msg, exception_class = nil)
      self.logger.warn(product) { msg }

      self.raise_exception(msg, exception_class)
    end

    def self.info(product, msg, exception_class = nil)
      self.logger.info(product) { msg }

      self.raise_exception(msg, exception_class)
    end

    def self.debug(product, msg, exception_class = nil)
      self.logger.debug(product) { msg }

      self.raise_exception(msg, exception_class)
    end

    def self.raise_exception(msg, exception_class)
      unless exception_class.nil?
        raise exception_class.new(msg)
      end
    end
  end
end
