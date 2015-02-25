require 'test/unit'
require 'yaml'
begin
  require File.join(File.dirname(__FILE__), '../lib/iron_core')
rescue Exception => ex
  puts "Could NOT load gem: " + ex.message
  raise ex
end

class TestBase < Test::Unit::TestCase

  def setup
    puts 'setup'
    @core = IronCore::Client.new("iron", "product", :gem => :net_http_persistent, :log_level=>Logger::DEBUG, 
    :http_proxy=>"http://whatever"
    )
  end

  def test_fake
  end

  ALL_OPS = [:get, :put, :post, :delete]


end
