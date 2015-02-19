module Cartero
module Commands
class Twilio < ::Cartero::Command
  def initialize
    super do |opts|
      opts.on("-D", "--data [DATA_FILE]", String,
        "File containing template data sets") do |data|
        @options.data = data
      end

      opts.on("-S", "--server [SERVER_NAME]", String,
        "Sets SMS server to use") do |server|
        @options.server = server
      end

      opts.on("-f", "--from [NUMBER]", String,
        "Sets SMS from number to use") do |from|
        @options.from = from
      end

      opts.on("-b", "--body [FILE_PATH]", String,
        "Sets SMS Text Body") do |body|
        @options.body = body
      end

      opts.on("-m", "--message [MESSAGE]", String,
        "Sets SMS message") do |message|
        @options.message = message
      end

      opts.on("-u", "--sid [SID]", String,
        "Sets Twilio Username") do |u|
        @options.sid = u
      end

      opts.on("-p", "--token [TOKEN]", String,
        "Sets Twilio password") do |p|
        @options.token = p
      end

      opts.on("-A", "--attachment [PATH_1||PATH_2||PATH_3]", String,
        "Sets Twilio MMS URL image paths to send") do |attachment|
        @options.attachment = attachment
      end

    end
  end

  def setup
    require 'erb'
    require 'twilio-ruby'

    if @options.data.nil?
      raise StandardError, "A data set [--data] must be provided"
    end

    if @options.body.nil? && @options.message.nil?
      raise StandardError, "At least a body [--body] or a straight message [--message] must be provided"
    end

    if @options.server.nil? && @options.username.nil? && @options.password.nil?
      raise StandardError, "A Twilio Server Credentials should be provided."
    elsif !Cartero::Commands::Servers.exists?(@options.server)
      raise StandardError, "Server with name #{@options.server} does not exist."
    else
      s = ::Cartero::Commands::Servers.server(@options.server)
      @server = JSON.parse(File.read(s),{:symbolize_names => true})

      if @server[:type].downcase != "twilio"
        raise StandardError, "Server with name #{@options.server} is not twilio type."
      end
    end

    unless @options.data.nil?
      @data = JSON.parse(File.read(File.expand_path @options.data),{:symbolize_names => true})
    end

    @from   = @options.from
    @sid 		= @options.sid
    @token 	= @options.token

    @client = ::Twilio::REST::Client.new(sid || server[:options][:sid], token || server[:options][:token])

    unless @options.body.nil?
      if ::Cartero::Commands::Templates.exists?(@options.body)
        @body = File.read("#{Cartero::TemplatesDir}/#{@options.body}.erb")
      else
        if File.exist?(File.expand_path @options.body)
          @body = File.read(File.expand_path @options.body)
        else
          raise StandardError, "Text Body Template (#{File.expand_path @options.body}) does not exists"
        end
      end
    end

    unless @options.attachment.nil?
      @attachment = @options.attachment.split("||")[0..9] # First 10 suported
    end

    unless @options.message.nil?
      @message = @options.message
    end

  end

  attr_reader :data
  attr_reader :server
  attr_reader :sid
  attr_reader :token
  attr_reader :message
  attr_reader :to
  attr_reader :from
  attr_reader :body
  attr_reader :ports
  attr_reader :client
  attr_reader :attachment

  def send
    data.each do |entity|
      if !entity[:phone].nil?
        yield entity if block_given?
        create_sms(entity)
      else
        Cartelo::Log.error "Entity #{entity} does not contain an :phone key."
      end
    end
  end

  def run
    send do |s|
      puts "Sending #{s[:phone]}"
    end
  end

  def create_sms(entity)
    sms = {}
    # set TO
    sms[:to] = entity[:phone]
    sms[:from] = from || entity[:from]

    entity[:payload] = ::Cartero::CryptoBox.encrypt(entity.to_json)

    # Add Text body if was provided.
    if !body.nil?
      sms[:body] = ERB.new(body).result(entity.get_binding)
    elsif !message.nil?
      sms[:body] = message
    else
      raise StandardError, "Entity #{entity} does not contain a body or a message key."
    end

    unless attachment.nil?
      sms[:media_url] = attachment
    end

    client.messages.create(sms)
  end
end
end
end
