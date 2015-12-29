module Cartero
module Commands
class LetsEncrypt < ::Cartero::Command
    def initialize
        super(
          name: "Lets Encrypt",
          description: "LetsEncrypt Command capable of generating a key and a cert for one of more domains.",
          author: ["Matias P. Brutti <matias [©] section9labs.com>"],
          type:"Infrastructure",
          license: "LGPL",
          references: [
            "https://section9labs.github.io/Cartero",
            "https://github.com/unixcharles/acme-client"
            ]

    ) do |opts|
      opts.on("-W", "--webserver WEBSERVER_FOLDER", String,
        "Sets the sinatra WebServer full path for payload creation") do |path|
        @options.path = path
      end

      opts.on("-K", "--private_key [KEY_PATH]", String,
				"Private key to use upon registration of new domain.") do |key|
				@options.private_key = key
			end

			opts.on("-D", "--domains [DOMAIN1,DOMAIN2]", String,
            "List of domains that certificate will be serving") do |domains|
        @options.domains = domains.split(",")
        end
      opts.on("-E", "--email [EMAIL]", String,
        "Email address attached to certificate and key.") do |e|
        @options.email = e
      end
			opts.on("-p", "--port [PORT]", Integer,
				"Port to listen on for file challenge. Default 80.") do |port|
				@options.port = port
			end
			opts.on("-e", "--endpoint [URI]", String,
				"LetsEncryption endpoint to talk to. By default one is provided.") do |endpoint|
				@options.endpoint = endpoint
			end
    end
  end

	def setup
 		require 'openssl'
    # Check for Cartero Sinatra App Path
    if @options.path != nil
      if File.exists?(@options.path)
			  @options.path = File.expand_path(@options.path) + "/"
      else
        raise StandardError, "Cartero App path provided does not exists."
      end
    end

		# Check for domains.
		if @options.domains.nil?
      raise StandardError, "One more more domains [--domains] must be provided. "
    end

		# Check for email
    if @options.email.nil?
      raise StandardError, "An email [--email] must be provided, in case private key does not exists."
    end

		# Check for Private keys
 		if @options.private_key.nil?
			puts "[!] - No Private key was provided. Generating a new one new_private_key.pem"
			@options.private_key = OpenSSL::PKey::RSA.new(2048)
			File.write("new_private_key.pem", @options.private_key.to_pem)
		elsif File.exists?(@options.private_key)
			@options.private_key = OpenSSL::PKey::RSA.new(File.read(File.expand_path(@options.private_key)))
		else
			raise StandardError, "File #{@options.private_key} does not exists"
		end

		if @options.endpoint.nil?
			@options.endpoint = 'https://acme-v01.api.letsencrypt.org/'
		end
 	end

  def run
		# We need an ACME server to talk to, see github.com/letsencrypt/boulder
		# Initialize the client
		require 'acme/client'
		client = Acme::Client.new(private_key: @options.private_key, endpoint: @options.endpoint)
		registration = client.register(contact: "mailto:"+@options.email)
		puts "[*] - Depending on endpoint you might be required to agree to terms."
		registration.agree_terms
		puts "[*] - Checking Authorization against #{@options.domains[0]}"
		authorization = client.authorize(domain: @options.domains[0])

		challenge = authorization.http01
		challenge.filename # => ".well-known/acme-challenge/:some_token"
		challenge.file_content # => 'string token and JWK thumbprint'
		challenge.content_type

		FileUtils.mkdir_p( File.join( '/tmp/public', File.dirname( challenge.filename ) ) )
		File.write( File.join( '/tmp/public', challenge.filename), challenge.file_content )

		@options.port ||= 80

		if @options.port < 1024
			puts "[!] - This command uses sudo because of port #{@options.port} is < 1024."
			sudo = "sudo "
		end

    puts "[*] - Starting a server on port #{@options.port}."
    puts "[*] - Remember this should be externally mapped to port 80." if @options.port != 80

		@cmd = IO.popen "#{sudo}ruby -run -e httpd /tmp/public -p #{@options.port} --bind-address 0.0.0.0 &"

    puts "[!] - Sleeping for a while to allow the token server to catch up..."
    sleep(3)

		begin
			# Once you are ready to serve the confirmation request you can proceed.
			challenge.request_verification # => true
			challenge.verify_status # => 'pending'
			sleep(2)
			while challenge.verify_status != 'valid' do
				puts "[*] - Waiting for valid status..."
				sleep(2)
			end

			csr = Acme::Client::CertificateRequest.new(names: @options.domains)

			certificate = client.new_certificate(csr) # => #<Acme::Client::Certificate ....>

			# Save the certificate and key
			File.write("#{@options.path}privkey.pem", certificate.request.private_key.to_pem)
			File.write("#{@options.path}cert.pem", certificate.to_pem)
			File.write("#{@options.path}chain.pem", certificate.chain_to_pem)
			File.write("#{@options.path}fullchain.pem", certificate.fullchain_to_pem)
		rescue
			after() # just to make sure we clean up :-)
		end
  end

  def after
  	Process.kill('INT', @cmd.pid)
		require 'fileutils'
		FileUtils.rm_rf('/tmp/public')
	# This is the place to run clean-up code.
  end
end
end
end
