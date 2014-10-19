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
	TemplatesApacheDir = Cartero::TemplatesDir + "/apache"
	TemplatesDataSetDir = Cartero::TemplatesDir + "/dataset"
	TemplatesMailDir = Cartero::TemplatesDir + "/mail"
	TemplatesWebServerDir = Cartero::TemplatesDir + "/webserver"
	SecretMaterial = Cartero::HomeDir + "/.secret_material"

	module Base

		def self.load_config
			if File.exist? Cartero::HomeDir + "/config"
				require 'json'
				Cartero.const_set(:GlobalConfig,JSON.parse(File.read(File.expand_path "~/.cartero/config")))
				if Cartero::GlobalConfig["metasploit"]
					Cartero.send(:remove_const, :MetasploitPath)
					Cartero.const_set(:MetasploitPath, File.expand_path(Cartero::GlobalConfig["metasploit"]["path"]))
				end
				ENV["EDITOR"] = Cartero::GlobalConfig.fetch("editor") if Cartero::GlobalConfig["editor"]
			end
		end

		def self.first_run?
			!File.directory? Cartero::HomeDir
		end

		def self.create_structure
			Dir.mkdir Cartero::HomeDir unless File.directory? Cartero::HomeDir
			Dir.mkdir Cartero::LogsDir unless File.directory? Cartero::LogsDir
			Dir.mkdir Cartero::DataDir unless File.directory? Cartero::DataDir
			Dir.mkdir Cartero::MongoDBDir unless File.directory? Cartero::MongoDBDir
			Dir.mkdir Cartero::ServersDir unless File.directory? Cartero::ServersDir
			Dir.mkdir Cartero::CmdsDir unless File.directory? Cartero::CmdsDir
			Dir.mkdir Cartero::PyldsDir unless File.directory? Cartero::PyldsDir
			Dir.mkdir Cartero::TemplatesDir unless File.directory? Cartero::TemplatesDir
			Dir.mkdir Cartero::TemplatesApacheDir unless File.directory? Cartero::TemplatesApacheDir
			Dir.mkdir Cartero::TemplatesDataSetDir unless File.directory? Cartero::TemplatesDataSetDir
			Dir.mkdir Cartero::TemplatesMailDir unless File.directory? Cartero::TemplatesMailDir
			Dir.mkdir Cartero::TemplatesWebServerDir unless File.directory? Cartero::TemplatesWebServerDir
			if Cartero::HomeDir + "/config"
				File.open(Cartero::HomeDir + "/config") do |config| 
					config << "{}\n"
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
	end
end
