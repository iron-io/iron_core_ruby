require_relative 'iron_error'

module IronCore
  class IronResponseError < IronCore::IronError
    def initialize(response)
      super(response.body)

      @response = response
    end

    def code
      return @response.code if @response
    end
  end
end
