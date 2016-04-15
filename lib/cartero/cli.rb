#encoding: utf-8
require 'optparse'
require 'ostruct'
require 'cartero/crypto_box'

module Cartero
  # Documentation for CLI
  class CLI
    attr_reader :options

    def initialize(args)
      @args = args
      @options = OpenStruct.new
      @options.verbose = true
      @options.commands = []
      @options.payloads = []

      Cartero::Base.initialize_commands
      Cartero::Base.initialize_payloads

      # Setup Correct Crypto Box ( AES || RBNACL )
      ::Cartero::CryptoBox.setup
      # Initialize Crypto Box
      ::Cartero::CryptoBox.init
    end

    def commands
      @options.commands
    end

    def payloads
      @options.payloads
    end

    def parse
      @parser = OptionParser.new do |opts|
        opts.banner = "Usage: cartero [options]"

        opts.separator ""
        opts.separator "List of Commands:\n    " + ::Cartero::COMMANDS.keys.join(", ")

        opts.separator ""
        opts.separator "List of Payloads:\n    " + ::Cartero::PAYLOADS.keys.join(", ")

        opts.separator ""
        opts.separator "Global options:"

        opts.on("-p", "--proxy [HOST:PORT]", String,
          "Sets TCPSocket Proxy server") do |pxy|
          @options.proxy = pry
          require 'socksify'
          url, port = pxy.split(":")
          TCPSocket.socks_server = url
          TCPSocket.socks_port = port.to_i
        end

        opts.on("-c", "--config [CONFIG_FILE]", String,
          "Provide a different cartero config file") do |config|
          @options.config_file = config
        end

        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          @options.verbose = v
        end

        opts.on("-p", "--ports [PORT_1,PORT_2,..,PORT_N]", String,
          "Global Flag to set Mailer and Webserver ports") do |p|
          @options.ports = p.split(",").map(&:to_i)
        end

        opts.on("-m", "--mongodb [HOST:PORT]", String,
          "Global flag to Set MongoDB bind_ip and port") do |p|
          @options.mongodb = p
        end

        opts.on("-d", "--debug", "Sets debug flag on/off") do
          @options.debug = true
        end

        opts.on("--editor [EDITOR]", String,
          "Edit Server") do |name|
          # User something besides ENV["EDITOR"].
          ENV["EDITOR"] = name
        end

        opts.separator ""
        opts.separator "Common options:"

        opts.on_tail("-h", "--help [COMMAND]", "Show this message") do |x|
          if x.nil?
            $stdout.puts opts
          else
            $stdout.puts subcommands[x].help
          end
          exit
        end

        opts.on("--list-commands", "Prints list of commands for bash completion") do
          $stdout.puts ::Cartero::COMMANDS.keys.join(" ")
        end

        opts.on("--list-payloads", "Prints list of payloads for bash completion") do
          $stdout.puts ::Cartero::PAYLOADS.keys.join(" ")
        end

        opts.on_tail("--list-options", "Show list of long available options") do
          $stdout.puts "--" + @parser.send(:top).long.map {|x| x[0]}.join(" --")
          exit
        end

        opts.on_tail("--list-short-options", "Show list of short available options") do
          $stdout.puts @parser.send(:top).long.map {|x| x[1].short[0]}.join(" ")
          exit
        end

        opts.on_tail("--version", "Shows cartero CLI version") do
          puts ::Cartero.version.join('.')
          exit
        end
      end
    end

    def run
      # Dealing with Global Options and Execution.
      begin
        if @args.empty?
          $stdout.puts @parser
          exit
        end
        @parser.order!
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument
        $stderr.puts "Invalid global option, try -h for usage"
        exit
      end
      # Now it is time to parse all Commands.
      # It is important to notice that order of commands does matter.
      # Commands split option flags. i.e.
      # > Cartero [ Global options ] command1 [command1 options ] command2 [command2 options]

      while !ARGV.empty?
        cmd = ARGV.shift
        if ::Cartero::COMMANDS.key?(cmd)
          begin
            command = ::Cartero::COMMANDS[cmd].new
            if ARGV.empty?
              $stdout.puts command.help
              exit
            end
            command.order!
            #command.args(ARGV)
            commands << command
          rescue OptionParser::InvalidOption, OptionParser::MissingArgument
            $stderr.puts "Invalid sub-command #{cmd} option, try -h for usage"
            exit
          rescue StandardError => e
            $stderr.puts e
            exit(1)
          end
        elsif ::Cartero::PAYLOADS.key?(cmd)
          begin
            payload = ::Cartero::PAYLOADS[cmd].new
            if ARGV.empty?
              $stdout.puts payload.help
              exit
            end
            payload.order!
            #payload.args(ARGV)
            commands << payload
          rescue OptionParser::InvalidOption, OptionParser::MissingArgument
            $stderr.puts "Invalid sub-payload #{cmd} option, try -h for usage"
            exit
          rescue StandardError => e
            $stderr.puts e
            exit(1)
          end
        else
          $stderr.puts "Invalid command or payload, try -h for usage"
          exit(1)
        end
      end

      # Running commands objects created on parsing.
      commands.each do |cmd_opt|
        begin
          cmd_opt.options.debug = true if @options.debug
          cmd_opt.options.verbose = true if @options.verbose
          cmd_opt.options.ports = @options.ports if @options.ports
          cmd_opt.options.mongodb = @options.mongodb if @options.mongodb
          cmd_opt.run
        rescue StandardError => e
          $stderr.puts e.to_s
          $stderr.puts e.backtrace if @options.debug
        end
      end
    end
  end
end
