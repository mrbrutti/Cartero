# Documentation for String
class String
  def camelize
    self.split("_").each(&:capitalize!).join("")
  end

  def underscore
    self.gsub(/(.)([A-Z])/,'\1_\2').downcase
  end
end

# Documentation for Cartero
# Just for Versioning
module Cartero
  COMMANDS = {}
  PAYLOADS = {}

  def self.version
    [0,4,1,"oscardelic"]
  end
end

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'cartero/base'
require 'cartero/cli'
require 'cartero/db'
require 'cartero/command'
