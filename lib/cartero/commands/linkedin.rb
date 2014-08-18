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

      opts.on("-l", "--list [CONNECTIONS|GROUPS]", [:connections, :groups],
              "List json of (connections or groups)") do |t|
        @options.list = t
      end

      opts.on("--send [MESSAGE|GROUP_UPDATE]", [:message, :group],
              "Send one or more (message/s or group/s updates)") do |t|
        @options.send_type = t
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
		require 'json'
		require 'multi_json'

		if @options.data.nil? and @options.list.nil?
			raise StandardError, "A data set [--data] must be provided"
		end

		if @options.body.nil? and @options.list.nil?
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

		unless @options.data.nil?
			@data = JSON.parse(File.read(File.expand_path @options.data),{:symbolize_names => true})
		end

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
		if !@options.list.nil?
			list = []; 
			case @options.list
			when /connections/
				@client.connections.all.map.each do |p|
					unless p.id == "private"
						list << { "id" => p.id, "name" => p.first_name, "last" => p.last_name, "title" => p.headline }
					end
				end
			when /groups/
				@client.group_memberships.all.map.each do |g|
					list << { "id" => g.id, "name" => g.group.name }
				end
			end
			print_json(list)
		else
			send do |s|
				puts "Sending Linkedin Message to #{s[:name]} #{s[:last]}\n\tStatus: #{s[:status]}"
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
				begin
				r = create_linkedin_message(entity, @options.send_type || "message")
				rescue StandardError => e
					entity[:status] = e
				end
				yield entity if block_given?
			else
				Cartelo::Log.error "Entity #{entity} does not contain an :email key."
			end
		end
	end

	def create_linkedin_message(entity, type)
		mail = {}
		
		# set TO, FROM and Subject
		mail[:to] 			= entity[:id]
		mail[:title]	= entity[:subject] 	|| subject

		# Add Text body if was provided.
		unless body.nil?
			mail[:summary] = ERB.new(body).result(entity.get_binding)
		end

		case type
		when /message/ then
			response = @client.send_message(mail[:title], mail[:summary], [mail[:to]])
		when /group/ then
			mail[:content] = entity[:content] || {}
			response = @client.add_group_share(mail[:to], mail)
		end
	end

	def print_json(list)
		unless file_save.nil?
			$stdout.puts "Saving data to file #{file_save}."
			f = File.new(file_save , "w+")
			f.puts JSON.pretty_generate list
			f.close
		else
			$stdout.puts JSON.pretty_generate list
		end
	end
end
end
end