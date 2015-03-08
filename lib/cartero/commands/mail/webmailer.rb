module Cartero
module Commands
# Documentation for WebMailer < ::Cartero::Command
class WebMailer < ::Cartero::Command
  def initialize
    super(name: "Web Form Email Command",
      description: "As the name states, it abuses(uses) open or vulnerable email forms available on the internet. This command is very useful when bypassing email filters during a penetration test. Since most webforms might be whitelisted.",
      author: ["Matias P. Brutti <matias [©] section9labs.com>"],
      type: "Delivery",
      license: "LGPL",
      references: ["https://section9labs.github.io/Cartero"]
      ) do |opts|
      opts.on("-R", "--raw RAW_REQUEST_FILE", String,
        "Sets WebMail Raw Request") do |rawfile|
        @options.raw = rawfile
      end

      opts.on("-S", "--server SERVER_NAME", String,
        "Sets WebMail server to use") do |server|
        @options.server = server
      end

      opts.on("-U", "--url URL:PORT", String,
        "Sets WebMail server url to use") do |rawfile|
        @options.raw = rawfile
      end

      opts.on("-H", "--headers HEADER:VAL\\nHEADER:VAL", String,
        "Sets WebMail Headers to use") do |headers|
        @options.headers = headers
      end

      opts.on("-C", "--cookies COOKIES", String,
        "Sets WebMail Cookies to use") do |cookies|
        @options.cookies = cookies
      end

      opts.on("-D", "--data DATA_FILE", String,
        "File containing template data sets") do |data|
        @options.data = data
      end

      opts.on("-s", "--subject EMAIL_SUBJECT", String,
        "Sets Email subject") do |subject|
        @options.subject = subject
      end

      opts.on("-f", "--from EMAIL_FROM", String,
        "Sets Email from") do |from|
        @options.from = from
      end

      opts.on("-r", "--reply-to EMAIL_REPLY_TO", String,
        "Sets Email reply-to") do |reply_to|
        @options.reply_to = reply_to
      end

      opts.on("-b", "--body REQUEST_FILE_PATH", String,
        "Sets Email Text request query Body") do |body|
        @options.body = body
      end

      opts.on("-p", "--ports PORT_1,PORT_2,..,PORT_N", String,
        "Sets Email Payload Ports to scan") do |p|
        @options.ports = p.split(",").map(&:to_i)
      end
    end
  end

  def setup
    require 'erb'

    require 'rest-client'

    if @options.data.nil?
      raise StandardError, "A data set [--data] must be provided"
    end

    if @options.body.nil?
      raise StandardError, "At least a body [--body] containing the POST/GET request parameters must be provided"
    end

    unless @options.raw.nil?
      if File.exist?(File.expand_path @options.raw)
        @raw = File.read(File.expand_path @options.raw)
      else
        raise StandardError, "Request file with name #{@options.raw} does not exist."
      end
    end

    unless @options.headers.nil?
      @headers = {}
      @options.headers.split("\n").each do |header|
        x = header.split(":"); @headers[x[0]] = x[1..-1].join(":")
      end
    end

    if @options.server.nil?
      raise StandardError, "Must provide a server of type webmailer."
    elsif !Cartero::Commands::Servers.exists?(@options.server)
      raise StandardError, "Server with name #{@options.server} does not exist."
    else
      s = ::Cartero::Commands::Servers.server(@options.server)
      @server = JSON.parse(File.read(s),{:symbolize_names => true})
      if @server[:type].downcase != "webmail"
        raise StandardError, "Server with name #{@options.server} is not webmail type."
      end
    end

    @data					= @options.data
    @from 				= @options.from
    @reply_to 		= @options.reply_to
    @subject 			= @options.subject
    @cookies 			= @options.cookies

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

    @data = JSON.parse(File.read(File.expand_path @options.data),{:symbolize_names => true})
    @ports = @options.ports || []
  end

  attr_reader :data
  attr_reader :raw
  attr_reader :cookies
  attr_reader :headers
  attr_reader :url
  attr_reader :server
  attr_reader :from
  attr_reader :reply_to
  attr_reader :subject
  attr_reader :body
  attr_reader :ports

  def send
    data.each do |entity|
      if !entity[:email].nil?
        yield entity if block_given?
        create_webemail(entity)
      else
        Cartelo::Log.error "Entity #{entity} does not contain an :email key."
      end
    end
  end

  def run
    send do |s|
      puts "Sending WebMail #{s[:email]}"
    end
  end

  def create_webemail(entity)
    entity[:from]	||= from
    entity[:reply_to] ||= reply_to
    entity[:subject] 	||= subject

    unless ports.empty?
      entity[:ports] ||= ports
    end

    entity[:payload] = ::Cartero::CryptoBox.encrypt(entity.to_json)

    if raw.nil?
      r = rest_webmail(entity)
    else
      r = raw_webmail(entity)
    end
    if !server[:confirmation].nil? # rubocop:disable Style/GuardClause
      unless r.scan(/#{server[:confirmation]}/).empty?
        $stdout.puts "WebMail request Confirmed."
      end
    end
  end

  def rest_webmail(entity)
    return RestClient::Request.execute(
      :method 	=> server[:options][:method].downcase,
      :url 			=> server[:options][:url] || url ,
      :payload 	=> ERB.new(body).result(entity.get_binding),
      :headers 	=> server[:options][:headers] || headers || {},
      :cookies 	=> server[:options][:cookies] || cookies || {}
    )
  end

  def raw_webmail(entity)
    uri = URI.parse(url)
    handcraft_request(uri.host,
      uri.port,
      uri.scheme == "https",
      ERB.new(raw).result(entity.get_binding)
    )
  end

  def handcraft_request(url, port, ssl, request_string)
    begin
      if ssl
        socket = TCPSocket.new(url, port.to_i)
        ssl_context = OpenSSL::SSL::SSLContext.new()
        unless ssl_context.verify_mode
           $stderr.puts "Warning: peer certificate won't be verified for this session."
           ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        sslsocket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
        sslsocket.sync_close = true
        sslsocket.connect
        sslsocket.puts(request_string)
        _header, response = sslsocket.gets(nil).split("\r\n\r\n")
      else
        request = TCPSocket.new(url, port.to_i)
        req = request_string
        request.print req
        _header, response = request.gets(nil).split("\r\n\r\n")
      end
    rescue
      $stderr.puts "Something went wrong sending request. Error: #{$!}"
    end
    return response
  end
end
end
end
