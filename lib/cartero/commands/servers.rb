require 'json'
require 'shellwords'
require 'erb'

module Cartero
module Commands
class Servers < ::Cartero::Command

  def initialize
    super do |opts|
      opts.on("-a","--add NAME", String,
        "Add Server") do |name|
        @options.name = name
        @options.action = "add"
      end

      opts.on("-e","--edit NAME", String,
        "Edit Server") do |name|
        @options.name = name
        @options.action = "edit"
      end

      opts.on("-d","--delete NAME", String,
        "Edit Server") do |name|
        @options.name = name
        @options.action = "delete"
      end

      opts.on("-l", "--list", String,
        "List servers") do
        @options.action = "list"
      end

      opts.separator ""
      opts.separator "Configuration options:"

      opts.on("-T", "--type TYPE", String,
        "Set the type") do |val|
        @options.type = val
      end

      opts.on("-U", "--url DOMAIN", String,
        "Set the Mail or WebMail url/address") do |val|
        @options.url = val
      end

      opts.on("-M", "--method METHOD", String,
        "Sets the WebMail Request Method to use [GET|POST]") do |val|
        @options.req_method = val
      end

      opts.on("--api-access API_KEY", String,
        "Sets the Linkedin API Access Key") do |val|
        @options.api_access = val
      end

      opts.on("--api-secret API_SECRET", String,
        "Sets the Linkedin API Secret Key") do |val|
        @options.api_secret = val
      end

      opts.on("--oauth-token OAUTH_TOKEN", String,
        "Sets the Linkedin OAuth Token Key") do |val|
        @options.oauth_token = val
      end

      opts.on("--oauth-secret OAUTH_SECRET", String,
        "Sets the Linkedin OAuth Secret Key") do |val|
        @options.oauth_secret = val
      end

    end
  end

  def run
    case @options.action
    when /add/
      Servers.create(@options.name, @options)
      $stdout.puts "Server #{@options.name} Created."
    when /edit/
      Servers.edit(@options.name)
      $stdout.puts "Server #{@options.name} Edited."
    when /delete/
      Servers.edit(@options.name)
      $stdout.puts "Server #{@options.name} Deleted."
    when /list/
      Servers.list.each do |s|
        $stdout.puts "    " + s
      end
    end
  end

  def self.list
    servers = []
    Dir.glob(::Cartero::ServersDir + "/**/*.json").each do |server|
      servers << File.basename(server).split(".")[0..-2].join(".")
      #servers << (File.read(server),{:symbolize_names => true})
    end
    servers
  end

  def self.exists?(name)
    File.exist?(self.server(name))
  end

  def self.server(name)
    servers = Dir.glob(::Cartero::ServersDir + "/**/*.json")
    server_file = servers.detect { |server| server =~ /^#{name}.json$/ }
    server_file || "#{Cartero::ServersDir}/#{name}.json"
  end

  def self.template(type=nil)
    case type
    when /smtp/
     "#{File.dirname(__FILE__)}/../../../templates/server/server.json"
    when /linkedin/
      "#{File.dirname(__FILE__)}/../../../templates/server/linkedin.json"
    when /webmail/
      "#{File.dirname(__FILE__)}/../../../templates/server/webmail.json"
    when /gvoice/
     "#{File.dirname(__FILE__)}/../../../templates/server/gvoice.json"
   when /twilio/
     "#{File.dirname(__FILE__)}/../../../templates/server/twilio.json"
    else
      "#{File.dirname(__FILE__)}/../../../templates/server/server.json"
    end
  end

  def self.create(name, options)
    if self.exists?(name)
      raise StandardError, "Server with name (#{name}) already exists"
    else
      s = server(name.shellescape)
      f = File.new(s, "w+")
      f.puts ::Cartero::Server.new(name.shellescape, options).render()
      f.close
      Kernel.system("$EDITOR #{s}")
    end
  end

  def self.edit(name)
    if !self.exists?(name)
      raise StandardError, "Server with name #{name} does not exist."
    else
      s = server(name.shellescape)
      Kernel.system("$EDITOR #{s}")
    end
  end

  def self.delete(name)
    if !self.exists?(name)
      raise StandardError, "Server with name #{name} does not exist."
    else
      File.delete(server(name.shellescape))
    end
  end
end
end

class Server
  def initialize(name, options)
    @name         = name
    @type         = options.type         || "smtp"
    @url          = options.url          || "subdomain.domain.com"
    @method       = options.req_method   || "POST"
    @api_access   = options.api_access   || "api_access_key"
    @api_secret   = options.api_secret   || "api_secret_key"
    @oauth_token  = options.oauth_token  || "oauth_token_key"
    @oauth_secret = options.oauth_secret || "oauth_secret_key"
  end

  def render
    ERB.new(File.read(::Cartero::Commands::Servers.template(@type))).result(binding)
  end
end
end
