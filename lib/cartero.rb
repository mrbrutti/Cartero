module Cartero
	COMMANDS = {}
	Version = [0,3,"ekologico"]
end

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'cartero/command'
require 'cartero/cli'
require 'cartero/db'
require 'cartero/base'
