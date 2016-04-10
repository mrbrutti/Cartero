#encoding: utf-8
# Documentatino for Cartero
# All static paths should be described here.
module Cartero
  MetasploitPath = File.expand_path("/usr/local/share/metasploit-framework")
  HomeDir = File.expand_path("~/.cartero")
  LogsDir = File.expand_path("~/.cartero/logs")
  DataDir = File.expand_path("~/.cartero/data")
  MongoDBDir = File.expand_path("~/.cartero/data/db")
  ServersDir = File.expand_path("~/.cartero/servers")
  CmdsDir = File.expand_path("~/.cartero/commands")
  PyldsDir = File.expand_path("~/.cartero/payloads")
  TemplatesDir = File.expand_path("~/.cartero/templates")
  TemplatesApacheDir = ::Cartero::TemplatesDir + "/apache"
  TemplatesDataSetDir = ::Cartero::TemplatesDir + "/dataset"
  TemplatesMailDir = ::Cartero::TemplatesDir + "/mail"
  TemplatesWebServerDir = ::Cartero::TemplatesDir + "/webserver"
  SecretMaterial = ::Cartero::HomeDir + "/.secret_material"

  # Documentation for Base module.
  # This module will contain several initialization methods
  # that will help the tool load and setup the enviroment.
  module Base
    def self.load_config
      if File.exist? ::Cartero::HomeDir + "/config"
        require 'json'
        Cartero.const_set(:GlobalConfig,JSON.parse(File.read(File.expand_path "~/.cartero/config")))
        if ::Cartero::GlobalConfig["metasploit"]
          Cartero.send(:remove_const, :MetasploitPath)
          Cartero.const_set(:MetasploitPath, File.expand_path(::Cartero::GlobalConfig["metasploit"]["path"]))
        end
        ENV["EDITOR"] ||= ::Cartero::GlobalConfig.fetch("editor") if ::Cartero::GlobalConfig["editor"]
      end
    end

    def self.first_run?
      !File.directory? ::Cartero::HomeDir
    end

    def self.bundle_cartero
      gemf = File.expand_path("../../../Gemfile", __FILE__)
      begin
        gem "bundler"
      rescue LoadError
        system("gem install bundler")
        Gem.clear_paths
      end
      system("bundler install --gemfile=\"#{gemf}\"")
    end

    def self.create_structure
      Dir.mkdir ::Cartero::HomeDir unless File.directory? ::Cartero::HomeDir
      Dir.mkdir ::Cartero::LogsDir unless File.directory? ::Cartero::LogsDir
      Dir.mkdir ::Cartero::DataDir unless File.directory? ::Cartero::DataDir
      Dir.mkdir ::Cartero::MongoDBDir unless File.directory? ::Cartero::MongoDBDir
      Dir.mkdir ::Cartero::ServersDir unless File.directory? ::Cartero::ServersDir
      Dir.mkdir ::Cartero::CmdsDir unless File.directory? ::Cartero::CmdsDir
      Dir.mkdir ::Cartero::PyldsDir unless File.directory? ::Cartero::PyldsDir
      Dir.mkdir ::Cartero::TemplatesDir unless File.directory? ::Cartero::TemplatesDir
      Dir.mkdir ::Cartero::TemplatesApacheDir unless File.directory? ::Cartero::TemplatesApacheDir
      Dir.mkdir ::Cartero::TemplatesDataSetDir unless File.directory? ::Cartero::TemplatesDataSetDir
      Dir.mkdir ::Cartero::TemplatesMailDir unless File.directory? ::Cartero::TemplatesMailDir
      Dir.mkdir ::Cartero::TemplatesWebServerDir unless File.directory? ::Cartero::TemplatesWebServerDir
      unless File.exist? ::Cartero::HomeDir + "/config"
        File.open(::Cartero::HomeDir + "/config", "w") do |config|
          config << "{
  \"editor\" : \"vim\",
  \"crypto\" : \"aes\",
  \"veilEvasion\" : {
    \"host\" : \"127.0.0.1\",
    \"port\" : \"4242\",
    \"path\" : \"~/Veil-Evasion/Veil-Evasion.py\",
    \"ssh\" : false,
    \"ssh_user\" :  \"root\"
  },
  \"metasploit\" : {
  		\"host\" : \"localhost\",
  		\"port\" : \"4567\",
  		\"username\" : \"msf\",
  		\"password\" : \"msf\",
  		\"db_name\" : \"msf\",
  		\"db_user\" : \"msf\",
  		\"db_pwd\" : \"\",
  		\"path\" : \"/opt/metasploit/app\",
  		\"ssh\" : true,
  		\"ssh_user\" :  \"root\"
  	},
  	\"smbtrap\" : {
  		\"host\" : \"localhost\",
  		\"path\" : \"~/SMBTrap/smbtrap/\",
  		\"ssh\" : true,
  		\"ssh_user\" :  \"root\"
  	},
  \"beef\" : {
    \"host\" : \"localhost\",
    \"path\" : \"/usr/local/share/beef\",
    \"port\" : \"3000\",
    \"ssh\"  : false,
    \"ssh_user\" : \"root\",
    \"username\" : \"beef\",
    \"password\" : \"beef\"
   }
}"
        end
      end
    end

    def self.check_editor
      ENV["EDITOR"].nil?
    end

    def self.load_commands
      Dir[File.dirname(__FILE__) + "/commands/**/*.rb"].each do |t|
        load t
      end

      Dir[ENV["HOME"] + "/.cartero/commands/**/*.rb"].each do |t|
        load t
      end
    end

    def self.load_payloads
      Dir[File.dirname(__FILE__) + "/payloads/**/*.rb"].each do |t|
        load t
      end

      Dir[ENV["HOME"] + "/.cartero/payloads/**/*.rb"].each do |t|
        load t
      end
    end

    def self.initialize_commands
      # Initialize all avilable loaded Commands that are parto of
      # ::Cartero::Commands and are its supper class is << ::::Cartero::Command.
      ::Cartero::Commands.constants.each do |klass|
        if RUBY_VERSION =~ /1.9.3/
          # get the constant from Object Concatenation on ruby 1.9.3
          # Kernel.const_get does not work using strings as a value.
          const = ::Object.const_get("Cartero").const_get("Commands").const_get(klass)
        else
          # Get the constant from the Kernel using the symbol
          const = Kernel.const_get("Cartero::Commands::#{klass}")
        end
        # Check if the plugin has a super class and if the type is Plugin
        if const.respond_to?(:superclass) && const.superclass == ::Cartero::Command
          ::Cartero::COMMANDS[klass.to_s] = const
        end
      end
    end

    def self.initialize_payloads
      # Initialize all avilable loaded Commands that are parto of
      # ::Cartero::Commands and are its supper class is << ::Cartero::Command.
      ::Cartero::Payloads.constants.each do |klass|
        if RUBY_VERSION =~ /1.9.3/
          # get the constant from Object Concatenation on ruby 1.9.3
          # Kernel.const_get does not work using strings as a value.
          const = ::Object.const_get("Cartero").const_get("Payloads").const_get(klass)
        else
          # Get the constant from the Kernel using the symbol
          const = Kernel.const_get("Cartero::Payloads::#{klass}")
        end
        # Check if the plugin has a super class and if the type is Plugin
        if const.respond_to?(:superclass) && const.superclass == ::Cartero::Payload
          ::Cartero::PAYLOADS[klass.to_s] = const
        end
      end
    end
  end
end
