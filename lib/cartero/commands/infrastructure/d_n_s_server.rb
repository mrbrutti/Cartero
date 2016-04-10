module Cartero
module Commands
class DNSServer < ::Cartero::Command

	description(
		name: "Malicious DNS Server",
		description: "Using the power of RubyDNS we counstracted a malicious" +
								 " DNS server that allows your to arbitrarely redirect specific " +
								 "domains and upstream others to a non-malicious DNS for normal resolution.",
		author: ["Matias Brutti <matias [©] section9labs.com>"],
		type:"Infrastructure",
		license: "LGPL",
		references: [
			"https://section9labs.github.io/Cartero",
			"https://github.com/ioquatix/rubydns"
			]
	)
	def initialize
		super do |opts|
			opts.on("-I", "--ip [IP_ADDRESS]", String,
    		"IP address of domain to hook") do |ip|
      	@options.ip = ip
    	end

      opts.on("-D", "--dns [DOMAIN_NAME]", String,
        "Domain to hook") do |dns|
        @options.dns = dns
      end

      opts.on("-F", "--file [FILENAME]", String,
        "List of domains to hook.") do |f|
        @options.file = f
      end

      opts.on("-L", "--listener [INTERFACE]", String,
        "IP Interface for DNS Server to listen. Default 0.0.0.0") do |l|
        @options.listener = l
      end

      opts.on("-P", "--listener-port [INTERFACE_PORT]", Integer,
        "Port for DNS Server to listen. Default 5300") do |x|
        @options.listener_port = x
      end

      opts.on("-U", "--upstremer [UPSTREAM_DNS]", String,
        "Upstream DNS Server to passthrough non-hooked DNS domains. Default 8.8.8.8") do |u|
        @options.upstream = u
      end

      opts.on("-G", "--upstremer-port [UPSTREAM_PORT]", Integer,
        "Port for Upstream DNS Server to listen. Default 5300") do |x|
        @options.upstream_port = x
      end
      # help() option already provided.
      # --list-options for auto-complete automatic.
    end
  end

  def setup
    require 'rubydns'
    @hooked_domains = []
    process_ip_dns_options
    process_file_options

    raise StandardError, "Port out of range" if !@options.listener_port.nil? && !((0..65535) === @options.listener_port)
    @interfaces = [
        [:udp, @options.listener || "0.0.0.0", @options.listener_port || 5300],
        [:tcp, @options.listener || "0.0.0.0", @options.listener_port || 5300]
    ]

    # Use upstream DNS for name resolution.
    raise StandardError, "Port out of range" if !@options.upstream_port.nil? && !((0..65535) === @options.upstream_port)
    @upstream = RubyDNS::Resolver.new(
      [
        [:udp, @options.upstream || "8.8.8.8", @options.upstream_port || 53],
        [:tcp, @options.upstream || "8.8.8.8", @options.upstream_port || 53]
      ]
    )

  end

  def run
    # Start the RubyDNS server
    hd = @hooked_domains
    u = @upstream
    RubyDNS::run_server(:listen => @interfaces) do
      @logger.level = Logger::ERROR # Arbitrary decision, but why not.
      # Hook malicious domains
      unless hd.empty?
        hd.each do |hook|
          match(/#{hook[:domain]}/, Resolv::DNS::Resource::IN::A) do |transaction|
            puts "[*] - HOOKED - Resolved #{hook[:domain]} for IP #{transaction.options[:peer]} with IP #{hook[:ip]}"
            transaction.respond!(hook[:ip])
          end
        end
      end

      # Default DNS handler
      otherwise do |transaction|
        puts "[*] - NORMAL - Resolved #{transaction.question} for IP #{transaction.options[:peer]}"
        transaction.passthrough!(u)
      end
    end
  end

  def after
    # This is the place to run clean-up code.
  end

  private
  def process_ip_dns_options
    if @options.dns && @options.ip
      @hooked_domains << { domain: @options.dns, ip: @options.ip }
    else
      raise StandardError, "Missing DNS for --ip option" if @options.dns.nil?
      raise StandardError, "Missing IP for --dns option" if @options.ip.nil?
    end
  end

  def process_file_options
    return if @options.file.nil?
    raise StandardError, "File does not exists" if File.exists?(File.expand_path(@options.file))
    dns_data = JSON.parse(File.read(File.expand_path(@options.file)))
    @hooked_domains.concat(dns_data)
  end
end
end
end
