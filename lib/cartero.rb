
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
require 'cartero/cartero_patches'
