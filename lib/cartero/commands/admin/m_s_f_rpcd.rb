#encoding: utf-8
module Cartero
module Commands
# Documentation for MSFRpcd < ::Cartero::Commands
class MSFRpcd < ::Cartero::Command
   def initialize
    super(name: "Metasploit MSFRPCd Interface",
      description: "This command is a simple control for metasploit's RPC protocol. ",
      author: ["Matias P. Brutti <matias [©] section9labs.com>"],
      type: "Admin",
      license: "LGPL",
      references: ["https://section9labs.github.io/Cartero"]
      ) do |opts|

      opts.on("-S", "--start", "Starts background RPC Server.") do
        @options.command = "start_rpc"
      end

      opts.on("-K", "--stop", "Stops background RPC Server.") do
        @options.command = "stop_rpc"
      end

      opts.on("-h", "--host HOST", String,
        "Sets address for RPC client/server") do |host|
        @options.host = host
      end

      opts.on("-p", "--port PORT", String,
        "Sets port for RPC client/server") do |port|
        @options.port = port
      end

      opts.on("-U", "--username USERNAME", String,
        "Sets username for RPC client/server") do |opt|
        @options.msfoptions = opt
      end

      opts.on("-P", "--password PASSWORD", String,
        "Sets password for RPC client/server") do |name|
        @options.msfname = name
      end
    end
  end
  attr_accessor :command

  def setup
    if @options.command.nil?
      raise StandardError, "A command [--start | --stop ] must be provided"
    end

    setup_rpc_client if @options.command != "start_rpc"
  end

  def run
    run_command if @options.command
  end

  private

  def setup_rpc_client
    require 'cartero/metasploit'
    @rpc_client = ::Cartero::Metasploit.new({
      "host" => @options.host || ::Cartero::GlobalConfig['metasploit']['host'] || '0.0.0.0',
      "port" => @options.port || ::Cartero::GlobalConfig['metasploit']['port'].to_i || 45678,
      "username" => @options.username ||Cartero::GlobalConfig['metasploit']['username'] || 'msf',
      "password" => @options.password ||Cartero::GlobalConfig['metasploit']['password'] || 'msf'
      })
    @rpc_client.login
  end

  def run_command
    case @options.command
    when "list"
      @rpc_client.list(list)
    when "start_rpc"
      system("/usr/local/share/metasploit-framework/msfrpcd -U #{@options.username ||Cartero::GlobalConfig['metasploit']['username'] || 'msf'}" +
        " -P #{@options.password ||Cartero::GlobalConfig['metasploit']['password'] || 'msf'} " +
        " -a #{@options.host || ::Cartero::GlobalConfig['metasploit']['host'] || '0.0.0.0'} " +
        " -p #{@options.port || ::Cartero::GlobalConfig['metasploit']['port'] || '45678'}"
      )
    when "stop_rpc"
      #Ghetto call - Not sure this is the best way to kill things :( Could not find anything else as of now.
      @rpc_client.call("core.stop")
    else
      puts "Command Not supported. You should not be here. "
    end
  end
end
end
end
