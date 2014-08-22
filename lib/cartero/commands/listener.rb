class String
  def camelize
    self.split("_").each {|s| s.capitalize! }.join("")
  end

  def underscore
    self.gsub(/(.)([A-Z])/,'\1_\2').downcase
  end
end

module Cartero
module Commands
class Listener < Cartero::Command
	def initialize
		super do |opts|
			opts.on("-i", "--ip [1.1.1.1]", String, 
    		"Sets IP interface, default is 0.0.0.0") do |ip|	      	
      	@options.ip = ip
    	end

    	opts.on("-p", "--ports [PORT_1,PORT_2,..,PORT_N]", String, 
    		"Sets Email Payload Ports to scan") do |p|	      	
      	@options.ports = p.split(",").map(&:to_i)
    	end
    	
    	opts.on("-s", "--ssl", "Run over SSL. [this also requires --sslcert and --sslkey]") do
    		@options.ssl = true
  		end
    	
    	opts.on("-C", "--sslcert [CERT_PATH]", String, 
    		"Sets Email Payload Ports to scan") do |cert|	      	
      	@options.sslcert = cert.split(",")
    	end

    	opts.on("-K", "--sslkey [KEY_PATH]", String, 
    		"Sets SSL key to use for Listener.") do |key|	      	
      	@options.sslkey = key.split(",")
    	end

    	opts.on("-V", "--views [VIEWS_FOLDER]", String, 
    		"Sets SSL Certificate to use for Listener.") do |file|	      	
      	@options.views = file
    	end

    	opts.on("-P", "--public [PUBLIC_FOLDER]", String, 
    		"Sets a Sinatra public_folder") do |file|	      	
      	@options.public_folder = file
    	end

    	opts.on("-W", "--webserver [WEBSERVER_FOLDER]", String,
    		"Sets the sinatra full path from cloner.") do |path|
    		app = path.split("/")[-1]
    		@options.customwebserver = path + "/" + app + ".rb"
    		@options.views = path + "/views"
    		@options.public_folder = path + "/static"
    	end

    	opts.on("--payload [PAYLOAD]", String, 
    		"Sets a payload download to serve on /download") do |file|	      	
      	@options.payload = file
    	end

    	opts.on("--customapp [CUSTOM_SINATRA]", String, 
    		"Sets a custom Sinatra::Base WebApp. Important, WebApp name should be camelized of filename") do |app|	      	
      	@options.customwebserver = app
    	end
    end
  end

  def setup
  	require 'cartero/models'
		require 'cartero/user_agent_parser'
		require 'cartero/puma_cartero_cli'

		if @options.ports.nil?
			raise StandardError, "No Port Provided [--ports]. Need to provide at least one binding port."
		end

		@puma = Puma::CarteroCLI.new([])
		@puma.options[:environment] = 'production'
		@puma.options[:min_threads] = 4
		@puma.options[:max_threads] = 16
		@puma.options[:quiet] = true
		#@puma.options[:workers] = 4
		# Set Another Listening IP interface. 
		@ip = @options.ip || "0.0.0.0"

		require "ipaddress"
		if !IPAddress.valid? @ip
			raise StandardError, "IP provided is not a valid address."
		end

		# Setting Default / Custom Sinatra Server. 
		if @options.customwebserver.nil?
			@web_server = WebServer
		else
			if File.exists?(File.expand_path(@options.customwebserver))
				# Load library from file.
				load "#{File.expand_path(@options.customwebserver)}" 
				# It is key that the name of the file reflect an uncamelize version of the library.
				# i.e. test_web_server.rb should be class TestWebServer
				@web_server = Module.const_get(File.basename(@options.customwebserver).split(".")[0..-2].join(".").camelize)
			else
				raise StandardError, "Custom WebServer file does not exists."
			end
		end

		# This is a constant given we use PUMA. So far no other option.
		@web_server.set :server, :puma
		@web_server.configure do
			@options.mongodb.nil? ? m = ["localhost", "27017"] : m = @options.mongodb.split(":")
			MongoMapper.connection = Mongo::Connection.new(m[0], m[1].to_i)
			MongoMapper.database = "Cartero"
		end

		# Allow to pass a Views Render Folder Path
		unless @options.views.nil?
			if File.directory?(File.expand_path(@options.views))
				@web_server.set :views, File.expand_path(@options.views)
			else
				raise StandardError, "View Folder does not exists."
			end
		end

		# Allow to pass a Public Folder Path
		unless @options.public_folder.nil?
			if File.directory?(File.expand_path(@options.public_folder))
				@web_server.set :public_folder, File.expand_path(@options.public_folder)
			else
				raise StandardError, "Public_folder Folder does not exists."
			end
		end
		
		# Allow to pass a payload for /download?key=XXXXXX
		unless @options.payload.nil?
			if File.exists?(File.expand_path(@options.payload))
				@web_server.set :payload_path, File.expand_path(@options.payload)
			else
				raise StandardError, " #{File.expand_path(@options.payload)} Payload does not exists."
			end
		end

		unless @options.metasploit.nil?
			# Process Metasploit Payload
		end
		
		# Passing PUMA the Sinatra WebApp we will be using. 
		@puma.options[:app] = @web_server
		
		# Handling SSL Options in Advance.
		# Handling Also port inside here, to ensure that 
		# if none provided 443 || 80 are correctly provided. 
		if @options.ssl.nil?
			@ports = @options.ports || [80]
		else
			@ports = @options.ports || [443]
			raise StandardError, "WebServer on SSL mode needs a cert path [ --sslcert ]." if @options.ssl_cert.nil?
			@ssl_cert_path = option.ssl_cert
			raise StandardError, "WebServer on SSL mode needs a key path.[ --sslkey ]" if @options.ssl_key.nil? 
			@ssl_key_path = option.ssl_key
		end

		# Generating Bind/s for each provided port.
		binds = []
		@options.ports.each do |p|
			if !@options.ssl.nil?
				binds << "ssl://#{@ip}:#{p}?key=#{@ssl_key_path}&cert=#{@ssl_cert_path}"
			else
				binds << "tcp://#{@ip}:#{p}"
			end
		end
		@puma.options[:binds] = binds

	end

	attr_accessor :ip
	attr_accessor :ports
	attr_accessor :ssl_key_path
	attr_accessor :ssl_cert_path
	attr_accessor :web_server

	def run
		@puma.run
	end
end
end

require 'rack'
require 'sinatra'
		
class WebServer < Sinatra::Base

	not_found do
		puts "#{Time.now} - IP #{request.ip} PORT #{request.port} - #{request.forwarded?} - #{request.user_agent}" 
		erb :error
	end

	get "/image" do
		process_info(params,request)
		return_img
	end

	get "/download" do
		process_info(params, request)
		return_payload
	end

  get "/click" do
  	process_info(params,request)
		return_img
	end

	private
	def process_info(params,request)
		if params[:key]
			begin
				data = JSON.parse(Cartero::CryptoBox.decrypt(params[:key]),{:symbolize_names => true})
			rescue RbNaCl::CryptoError
				puts "Entity Could not be decrypt it."
			rescue ArgumentError
				puts "Entity Could not be parsed correctly."
			end

			person = Person.where(:email => data[:email]).first

			if person.nil?
				begin 
					person = Person.new(:email => data[:email])
					person.save!
				rescue MongoMapper::DocumentNotValid
					person = Person.where(:email => data[:email]).first
				end
			end
			
			person.campaigns << data[:subject] unless person.campaigns.include?(data[:subject])
			person.responded << "#{request.ip}:#{request.port}" unless person.responded.include?("#{request.ip}:#{request.port}")
			if params[:username] || params[:password]
				person.credentials << { 
					:username => params[:username], 
					:password => params[:password]
				}
			end

			ua = Cartero::UserAgentParser.new(request.user_agent)
			ua.parse

			person.hits << Hit.new(
				:ip 				=> request.ip,
				:port 			=> request.port,
				:domain 		=> request.host,
				:path       => request.path_info,
				:ports 			=> data[:ports],
				:time 			=> Time.now,
				:user_agent => request.user_agent,
				:forwarded 	=> request.forwarded?,
				:data 			=> data,
				:ua_comp		=> ua.comp,
				:ua_os 			=> ua.os,
				:ua_browser => ua.browser,
				:ua_engine	=> ua.engine,
				:ua_platform => ua.platform,
				:ua_lang		=> ua.lang
			)

			person.save!
			puts "#{Time.now} - PERSON #{person.email} - IP #{request.ip} PORT #{request.port} PATH #{request.path_info} - USER_AGENT #{request.user_agent}"
		else
			puts "#{Time.now} - PERSON #{"--"} - IP #{request.ip} PORT #{request.port} PATH #{request.path_info} - USER_AGENT #{request.user_agent}"
		end
	end

	def return_payload
		return send_file(settings.payload_path, :disposition => :inline)
	end

	def return_img
		return send_file(File.expand_path("../../../data/images/image.jpg", __FILE__), 
			:filename => "white.jpg", 
			:type => :jpg, 
			:disposition => :inline)
	end
end
end