require 'iron_core/error'

module IronCore
  class ConfigurationError < IronCore::Error
    def initialize(message)
      super(message)
    end
  end
end
