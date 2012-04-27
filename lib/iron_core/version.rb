module IronCore
  @@version = nil

  def self.version
    @@version ||= File.read(File.dirname(__FILE__) + '/../../VERSION').strip
  end
end
