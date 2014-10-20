module Cartero
	module DB
		def self.start(ip=nil, port=nil)
			case RUBY_PLATFORM
			when /linux|darwin/
				mongod = "mongod --fork"
				#$stdout.puts "Launching mongodb"
				system( mongod + " --dbpath=" + Cartero::MongoDBDir + " --logpath=" + Cartero::LogsDir + "/mongodb.log" + " --bind_ip #{ip || "localhost"} --port #{port || "27017"}" + " --logappend" + "> /dev/null")
				sleep(1)
			when /mingw|mswin/
				$stdout.puts "TODO: Manual Launch. !!! Make sure mongodb is running. !!!"
				sleep(1)
			end
		rescue => e
			$stderr.puts "Something went wrong starting db. #{e.to_s}"
			exit(0)
		end

		def self.stop
			#$stdout.puts "Stopping Mongodb"
			MongoMapper.connection['admin'].command(:shutdown => 1)
			$stdout.puts "" if RUBY_PLATFORM =~ /mingw|mswin/
		rescue StandardError => e
			#$stderr.puts "Looks like there is not an establish connection to shutdown."
			#$stderr.puts "Killing Process"
			Process.kill(2,File.read(Cartero::MongoDBDir + "/mongod.lock").strip.to_i)
		end
	end
end