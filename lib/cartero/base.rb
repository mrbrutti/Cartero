module Cartero
	HomeDir = File.expand_path ("~/.cartero")
	LogsDir = File.expand_path ("~/.cartero/logs")
	DataDir = File.expand_path ("~/.cartero/data")
	MongoDBDir = File.expand_path ("~/.cartero/data/db")
	ServersDir = File.expand_path ("~/.cartero/servers")
	CmdsDir = File.expand_path ("~/.cartero/commands")
	TemplatesDir = File.expand_path ("~/.cartero/templates")
	TemplatesApacheDir = Cartero::TemplatesDir + "/apache"
	TemplatesDataSetDir = Cartero::TemplatesDir + "/dataset"
	TemplatesMailDir = Cartero::TemplatesDir + "/mail"
	TemplatesWebServerDir = Cartero::TemplatesDir + "/webserver"
	SecretMaterial = Cartero::HomeDir + "/.secret_material"
	
	module Base
		def self.first_run?
			!File.directory? Cartero::HomeDir
		end

		def self.create_structure
			Dir.mkdir Cartero::HomeDir unless File.directory? Cartero::HomeDir
			Dir.mkdir Cartero::LogsDir unless File.directory? Cartero::LogsDir
			Dir.mkdir Cartero::DataDir unless File.directory? Cartero::DataDir
			Dir.mkdir Cartero::DataDir unless File.directory? Cartero::DataDir
			Dir.mkdir Cartero::MongoDBDir unless File.directory? Cartero::MongoDBDir
			Dir.mkdir Cartero::ServersDir unless File.directory? Cartero::ServersDir
			Dir.mkdir Cartero::CmdsDir unless File.directory? Cartero::CmdsDir
			Dir.mkdir Cartero::TemplatesDir unless File.directory? Cartero::TemplatesDir
			Dir.mkdir Cartero::TemplatesWebServerDir unless File.directory? Cartero::TemplatesWebServersDir
			Dir.mkdir Cartero::TemplatesApacheDir unless File.directory? Cartero::TemplatesApacheDir
		end

		def self.check_editor
			ENV["EDITOR"].nil?
		end

    def self.load_commands
  	  Dir[File.dirname(__FILE__) + "/commands/*.rb"].each do |t|
  	    load t
  	  end

  	  Dir[ENV["HOME"] + "/.cartero/commands/*.rb"].each do |t|
  	    load t
  	  end
  	end
	end
end