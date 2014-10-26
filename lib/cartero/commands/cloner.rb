# encoding: UTF-8

module Cartero
module Commands
class Cloner < Cartero::Command
	def initialize
		super do |opts|
			opts.on("-U", "--url [URL_PATH]", String,
    		"Full Path of site to clone") do |url|
      	@options.url = url
    	end

    	opts.on("-W", "--webserver [SERVER_NAME]", String,
    		"Sets WebServer name to use") do |ws|
      	@options.webserver = ws
    	end

    	opts.on("-p", "--path [PATH]", String,
    		"Sets path to save webserver") do |path|
      	@options.path = path
    	end

    	opts.on("--useragent [UA_STRING]", String,
    		"Sets user agent for cloning") do |payload|
      	@options.useragent = payload
    	end

    	opts.on("--wget", "Use wget to clone url") do
    		@options.wget = true
  		end

    	opts.on("--apache", "Generate Apache Proxy conf") do
    		@options.apache = true
  		end

			opts.on("-P", "--payload [PAYLOAD_PATH]", String,
				"Sets payload path") do |payload|
				@options.payload = payload
			end
    end
	end
	attr_accessor :url
	attr_accessor :url_route
	attr_accessor :path
	attr_accessor :webserver
	attr_accessor :forms_routes
	attr_accessor :payload
	attr_accessor :wget
	attr_accessor :apache
	attr_accessor :useragent
	attr_accessor :domain_info

	def setup
		require 'erb'
		require 'uri'

		if @options.url.nil?
			raise StandardError, "A url [--url] must be provided"
		end

		if @options.webserver.nil?
			raise StandardError, "A WebServer name [--webserver] must be provided"
		end

		if @options.path.nil?
			puts "Saving WebServer to [ #{Cartero::TemplatesWebServerDir} ]"
			@options.path = Cartero::TemplatesWebServerDir
		end

		if ( @options.msfpayload.nil? && ( !@options.msfoptions.nil? || !@options.msfname.nil? || !@options.msfarch.nil? ))
			raise StandardError, "Option requires a --msfpayload"
		elsif ( !@options.msfpayload.nil? )
			@msfpayload = true
		end

		@msfvenom		= @options.msfvenom
		@url 				= @options.url
		@url_route 	= URI.parse(@options.url).path
		@path 			= File.expand_path @options.path
		@webserver 	= @options.webserver
		@payload 		= @options.payload
		@wget 			= @options.wget
		@apache 		= @options.apache
		@useragent 	= @options.useragent || "Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2049.0 Safari/537.36"
	end


	def run
		puts "Cloning URL #{@url}"
		create_structure
		clone

		if apache
			puts "Generating Apache mod_proxy config file"
			create_apache_conf
		end
	end

	def create_structure
		name = webserver.underscore
		Dir.mkdir path + "/"  + name unless File.directory?(path + "/"  + name)
		Dir.mkdir path + "/"  + name + "/static" unless File.directory? path + "/"  + name + "/static"
		Dir.mkdir path + "/"  + name + "/views" unless File.directory? path + "/"  + name + "/views"
	end

	def clone
		require 'mechanize'
		require 'uri'
		mechanize = Mechanize.new
		mechanize.user_agent = useragent
		page = mechanize.get(url)

		forms_routes = page.forms.map {|x| [x.method.downcase , URI.parse(x.action).path ] }

		@domain_info = {
			:url 					=> url,
			:url_route    => url_route,
			:path 				=> path,
			:webserver 		=> webserver,
			:forms_routes => forms_routes,
			:payload 			=> payload
		}

		ws = File.new(@options.path + "/"  + webserver.underscore + "/" + webserver.underscore + ".rb", "w")
		ws << ERB.new(File.read(File.dirname(__FILE__) + "/../../../templates/webserver/template.rb.erb")).result(domain_info.get_binding)
		ws.close
		if wget
			system("wget --no-check-certificate -O \"#{@options.path + "/" + webserver.underscore + "/views/index.erb"}\" -c -k  \"#{url}\"")
		else
			create_index(page)
		end
	end

	def create_index(page)
		zurl = URI.parse(url)

		page.search("//*/@href").each do |href|
			unless href.value.start_with?("javascript:")
				link = URI.parse(href.value)
				if link.host.nil? && link.scheme != "mailto" && link.scheme != "javascript"
					link.host = zurl.host
					link.scheme = zurl.scheme
					href.value = link.to_s
				end
			end
		end

		page.search("//*/@src").each do |src|
			unless src.value.start_with?("javascript:")
				link = URI.parse(src.value)
				if link.host.nil? && link.scheme != "mailto"
					link.host = zurl.host
					link.scheme = zurl.scheme
					src.value = link.to_s
				end
			end
		end

		page.search("//form/@action").each do |form|
			form.value = URI.parse(form.value).path
		end
		
		content_type = page.header["content-type"].split("=")[-1]

		f = File.new(@options.path + "/" + webserver.underscore + "/views/index.erb", "w") 
		if content_type != ""
			f << page.parser.to_s.force_encoding(content_type).encode('utf-8')
		else
			f << page.parser.to_s
		end
		f.close
	end

	def create_apache_conf
		ws = File.new(@options.path + "/"  + webserver.underscore + "/" + webserver.underscore + "_apache_module_.conf", "w")
		ws << ERB.new(File.read(File.dirname(__FILE__) + "/../../../templates/apache/apache_proxy.conf.erb")).result(domain_info.get_binding)
		ws.close
	end

end
end
end
