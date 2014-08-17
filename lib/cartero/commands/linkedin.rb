# Hack to Hash to we can use 
# the private binding() method on ERB.
class Hash
	def get_binding
		binding()
	end
end

module Cartero
module Commands
class LinkedIn < Cartero::Command
	def initialize
		super do |opts|
			opts.on("-D", "--data [DATA_FILE]", String, 
    		"File containing template data sets") do |data|	      	
      	@options.data = data
    	end

    	opts.on("-S", "--server [SERVER_NAME]", String, 
    		"Sets Email server to use") do |server|	      	
      	@options.server = server
    	end

    	opts.on("-s", "--subject [MESSAGE_SUBJECT]", String, 
    		"Sets LinkedIn Message subject") do |subject|	      	
      	@options.subject = subject
    	end

    	opts.on("-b", "--body [FILE_PATH]", String, 
    		"Sets LinkedIn Message Body") do |body|	      	
      	@options.body = body
    	end

    	opts.on("-l", "--list-connections", 
    		"Show Summary of connections") do	      	
      	@options.list_connections = true
    	end

    	opts.on("-o", "--save [FILE_PATH]", String, 
    		"Sets LinkedIn Message Body") do |f|	      	
      	@options.file_save = f
    	end
    end
	end
	
	attr_reader :data
	attr_reader :server
	attr_reader :from
	attr_reader :subject
	attr_reader :charset
	attr_reader :body
	attr_accessor :file_save
	attr_accessor :client

	def setup
		require 'erb'
		require 'linkedin'

		if @options.data.nil? && @options.list_connections.nil?
			raise StandardError, "A data set [--data] must be provided"
		end

		if @options.body.nil? && @options.list_connections.nil?
			raise StandardError, "A body [--body] must be provided"
		end

		if @options.server.nil? 
			raise StandardError, "A Linkedin Server Credentials should be provided."
		elsif !Cartero::Commands::Servers.exists?(@options.server)
  		raise StandardError, "Server with name #{@options.server} does not exist."
  	else
			s = Cartero::Commands::Servers.server(@options.server)
			@server = JSON.parse(File.read(s),{:symbolize_names => true})
		end

		@data = JSON.parse(File.read(File.expand_path @options.data),{:symbolize_names => true})
		@from 				= @options.from
		@subject 			= @options.subject
		@file_save    = @options.file_save
		
		unless @options.body.nil?
			if Cartero::Commands::Templates.exists?(@options.body)
				@body = File.read("#{Cartero::TemplatesDir}/#{@options.body}.erb")
			else
				if File.exists?(File.expand_path @options.body)
					@body = File.read(File.expand_path @options.body)
				else
					raise StandardError, "Text Body Template (#{File.expand_path @options.body}) does not exists"
				end
				if @server[:type].downcase != "linkedin"
					raise StandardError, "Server with name #{@options.server} is not linkedin type."
				end
			end
		end
		login
	end

	def run
		unless @options.list_connections.nil?
			require 'json'
			list = []
			@client.connections.all.map.each do |p|
				unless p.id == "private"
					list << { 
						"id" => p.id, 
						"name" => p.first_name, 
						"last" => p.last_name,
						"title" => p.headline
					}
				end
			end
			unless file_save.nil?
				f = File.new(file_save , "w+")
				f.puts JSON.pretty_generate list
				f.close
			else
				$stdout.puts JSON.pretty_generate list
			end
		else
			send do |s|
				puts "Sending Linkedin Message to #{s[:name]} #{s[:last]}"
			end
		end
	end


	def login
		@client = ::LinkedIn::Client.new(server[:options][:api_access], server[:options][:api_secret])
		@client.authorize_from_access server[:options][:oauth_token], server[:options][:oauth_secret]
	end
	
	def send
		data.each do |entity|
			if !entity[:id].nil?
				yield entity if block_given?
				create_linkedin_email(entity)
			else
				Cartelo::Log.error "Entity #{entity} does not contain an :email key."
			end
		end
	end

	def create_linkedin_email(entity)
		mail = {}
		
		# set TO, FROM and Subject
		mail[:to] 			= entity[:id]
		mail[:subject]	= entity[:subject] 	|| subject

		# Add Text body if was provided.
		unless body.nil?
			mail[:body] = ERB.new(body).result(entity.get_binding)
		end
		p @client.profile
		response = @client.send_message(mail[:subject], mail[:body], [mail[:to]])
	end
end
end
end