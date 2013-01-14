require 'iron_core/error'

module IronCore
  class ResponseError < IronCore::Error
    def initialize(response)
      super(response.body)

      @response = response
    end

    def code
      return @response.code if @response
    end
  end
end
