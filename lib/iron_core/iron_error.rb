module IronCore
  class IronError < Exception

    def initialize(response)
      super(response.body)
      @response = response
    end

    def code
      return @response.code if @response
    end

  end
end
