require 'optparse'
require 'ostruct'

# Hack to Hash to we can use 
# the private binding() method on ERB.
class Hash
	def get_binding
		binding()
	end
end

module Cartero
	class Command
		@@disable_override = false
		attr_accessor :options
		attr_accessor :args

		def initialize(&block)
			@options = OpenStruct.new
			@options.verbose 		= false
			@options.debug 			= false
			@options.commands 		= []

			parse &block
		end

		def setup
		end

		def after
	  end

		def help
			@parser.help
		end

		def order!
			@parser.order!
		end

		def name
			self.class.name.split("::")[-1]
		end
		
		def parse(&block)
			@parser = OptionParser.new do |opts|
				opts.banner = "Usage: Cartero #{name} [options]"  
				block.call(opts)

				opts.separator ""
      	opts.separator "Common options:"
				opts.on_tail("-h", "--help", "Show this message") do
	        puts @parser
	        exit
	      end
	      opts.on_tail("--list-options", "Show list of available options") do
	        $stdout.puts "--" + @parser.send(:top).long.map {|x| x[0]}.join(" --")
	        exit
	      end
			end
		end
		
	  def self.method_added name
	    unless @@disable_override
	      if name == :run
	        @@disable_override = true # to stop the new build method 
	        self.send :alias_method, :sub_run, :run
	        self.send :remove_method, :run
	        self.send :define_method, :run do
	          setup
	          sub_run
	          after
	        end
	        @@disable_override = false
	      end
	    end
	  end
	end
end

module Cartero
	class Payload < Cartero::Command
	end
end