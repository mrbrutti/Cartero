#encoding: utf-8
module Cartero
module Commands
class Xmpp < ::Cartero::Command

	description(
		name: "Mass XMPP Messenger",
		description: "A simple XMPP Client capable of sending templated messages to multiple users.",
		author: ["Matias P. Brutti <matias [©] section9labs.com>"],
		type:"Social",
		license: "LGPL",
		references: [
			"https://section9labs.github.io/Cartero",
			"https://github.com/xmpp4r/xmpp4r"
			]
	)
	def initialize
		super do |opts|
			opts.on("-D", "--data DATA_FILE", String,
        "File containing template data sets") do |data|
        @options.data = data
      end

      opts.on("-S", "--server SERVER_NAME", String,
        "Sets Jabber server to use") do |server|
        @options.server = server
      end

			opts.on("-B", "--body FILENAME", String,
        "Sets message subject") do |b|
        @options.body = b
      end

			opts.on("-m", "--message MESSAGE", String,
        "Sets message subject") do |m|
        @options.message = m
      end

			opts.on("-U", "--username JID", String,
    		"Optional way of setting up jabber username") do |u|
      	@options.jid = u
    	end

      opts.on("-P", "--password PASSWORD", String,
        "Optional way of setting up Jabber password") do |p|
        @options.password = p
      end

			opts.on("-J", "--server-address ADDRESS:PORT", String,
        "Optinal way of passing server uri and port") do |s|
        url, port = s.split(":")
				@options.address = url
				@options.port = port
      end

    end
  end

  def setup
	  require 'xmpp4r'

    if @options.data.nil?
			raise StandardError, "A data set [--data] must be provided"
		elsif !File.exist?(File.expand_path(@options.data))
			raise StandardError, "A valid data set file must be provided. File does not exists"
		else
			@options.data = JSON.parse(File.read(File.expand_path(@options.data)),{:symbolize_names => true})
		end

		# Check for Server config
    if @options.server.nil? && @options.address && options.port
      @options.server = {
				:name => "default",
				:type => :jabber,
				:options => {
					:address => @options.address,
					:port => @options.port
				}
			}
    elsif !Cartero::Commands::Servers.exists?(@options.server)
      raise StandardError, "Server with name #{@options.server} does not exist."
    else
      s = ::Cartero::Commands::Servers.server(@options.server)
      @options.server = JSON.parse(File.read(s),{:symbolize_names => true})
    end
		# Check if JID / Password provided

		# else require JID
		if @options.jid.nil? && @options.server[:options][:jid].nil?
			raise StandardError, "Missing JabberID --username and/or a --server with proper configuration needed."
		end

		# require password
		if @options.password.nil? && @options.server[:options][:password].nil?
			raise StandardError, "Missing password --password and/or a --server with proper configuration needed."
		end

		# Check if body is provided. We need a message.
    if !@options.body.nil?
      if ::Cartero::Commands::Templates.exists?(@options.body)
        @options.body = File.read("#{Cartero::TemplatesDir}/#{@options.body}.erb")
      else
        if File.exist?(File.expand_path(@options.body))
          @options.body = File.read(File.expand_path(@options.body))
        else
          raise StandardError, "A template message (#{File.expand_path(@options.body)}) does not exists"
        end
      end
		elsif !@options.message.nil?
			@options.body = @options.message
		else
			raise StandardError, "A --body or a --message is required"
		end

		@client = Jabber::Client.new(Jabber::JID.new(@options.jid || @options.server[:options][:jid]))
		@client.connect(@options.server[:options][:address], @options.server[:options][:port].to_i || 5222)
		@client.auth(@options.password || @options.server[:options][:password])
		sleep(1)
		@client.send(Jabber::Presence.new)
	end

  def run
		# Send messages
		@options.data.each do |receiver|
			unless receiver[:email].nil?
			  # This is added, so things will work. I guess if you send stuff to quick your messages won't be sent.
			  add_user(receiver[:email])
				sleep(1)
				send_message(receiver)
				#TODO: send_attachment(receiver) if receiver[:attachments] || @options.attachments
			end
		end
	end

	def after
		@client.close
  end

	private

	def add_user(e)
		 s_request = Jabber::Presence.new.set_type(:subscribe)
		 s_request.to = Jabber::JID.new(e)
		 @client.send(s_request)
	end

	def send_message(r)
		# Adding payload to "encrypted" data for later retrieval.
		r[:payload] = ::Cartero::CryptoBox.encrypt(r.to_json)
		# Build Templated message if nesseary :-)
		b = ERB.new(r[:message] || @options.body).result(r.get_binding)
		# Create message
    m = Jabber::Message.new(r[:email],b).set_type(:chat)
		# Send actual message
		@client.send(m)

		$stdout.puts "Sending message to #{r[:email]}"
	end

	def send_attachment(r)
		# Send attachment.
	end
end
end
end
