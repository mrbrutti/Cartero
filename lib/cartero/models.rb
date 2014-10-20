begin
	require 'mongo_mapper'
rescue
	require 'active_support'
	require 'mongo_mapper'
end

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/models')

require 'person'
require 'hit'
require 'credential'