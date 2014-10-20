class String
  def camelize
    self.split("_").each {|s| s.capitalize! }.join("")
  end

  def underscore
    self.gsub(/(.)([A-Z])/,'\1_\2').downcase
  end
end

module Cartero
	COMMANDS = {}
	PAYLOADS = {}
	Version = [0,3,"ekologico"]
end

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'cartero/command'
require 'cartero/cli'
require 'cartero/db'
require 'cartero/base'
