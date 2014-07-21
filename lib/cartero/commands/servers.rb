#{
#	:name => "Server Name"
#	:type => "smtp or sendmail"
#	:options => {
#		:address        => 'smtp.yourserver.com',
#    :port           => '25',
#    :user_name      => 'user',
#    :password       => 'password',
#    :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
#    :domain         => "localhost.localdomain" # the HELO domain provided by the client to the server
#	}
#}

require 'json'
require 'shellwords'
require 'erb'

module Cartero
module Commands
class Servers < Cartero::Command

  def initialize
    super do |opts|
      opts.on("-a","--add [NAME]", String, 
        "Add Server") do |name|         
        @options.name = name
        @options.action = "add"
      end

      opts.on("-e","--edit [NAME]", String, 
        "Edit Server") do |name|          
        @options.name = name
        @options.action = "edit"
      end

      opts.on("-d","--delete [NAME]", String, 
        "Edit Server") do |name|          
        @options.name = name
        @options.action = "delete"
      end

      opts.on("-l", "--list", String, 
        "List servers") do |name|
        @options.action = "list"
      end
    end
  end

  def run
    case @options.action
    when /add/
      Servers.create(@options.name)
      $stdout.puts "Server #{@options.name} Created."
    when /edit/
      Servers.edit(@options.name)
      $stdout.puts "Server #{@options.name} Edited."
    when /delete/
      Servers.edit(@options.name)
      $stdout.puts "Server #{@options.name} Deleted."
    when /list/
      Servers.list.each do |s|
        $stdout.puts "    " + s
      end
    end
  end

	def self.list
		servers = []
		Dir.glob(Cartero::ServersDir + "/**/*.json").each do |server|
			servers << File.basename(server).split(".")[0..-2].join(".")
			#servers << (File.read(server),{:symbolize_names => true})
		end
		servers
	end

	def self.exists?(name)
		File.exists?(self.server(name))
	end

	def self.server(name)
    servers = Dir.glob(Cartero::ServersDir + "/**/*.json")
    server_file = servers.detect { |server| server =~ /^#{name}.json$/ }
    server_file || "#{Cartero::ServersDir}/#{name}.json"
  end

	def self.template
  	"#{File.dirname(__FILE__)}/../../../templates/server/server.json"
  end

  def self.create(name)
  	if self.exists?(name)
  		raise StandardError, "Server with name (#{name}) already exists"
  	else
  		s = server(name.shellescape)
  		f = File.new(s, "w+")
  		f.puts Cartero::Server.new(name.shellescape).render()
  		f.close
  		Kernel.system("$EDITOR #{s}")
  	end
  end

  def self.edit(name)
  	if !self.exists?(name)
  		raise StandardError, "Server with name #{name} does not exist."
  	else
  		s = server(name.shellescape)
  		Kernel.system("$EDITOR #{s}")
  	end
  end

  def self.delete(name)
  	if !self.exists?(name)
  		raise StandardError, "Server with name #{name} does not exist."
  	else
  		File.delete(server(name.shellescape))
  	end
  end
end
end

class Server
	def initialize(name, type=nil)
		@name = name
		@type = type || "smtp"
	end

	def render
		ERB.new(File.read(Cartero::Commands::Servers.template)).result(binding)
	end
end
end