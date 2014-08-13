module IronCore
  class IronTokenProvider
    def initialize(token)
      @token = token
    end

    def token
      puts "IRON TOKEN #{@token}"
      @token
    end
  end
end