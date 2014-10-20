module Cartero
module Commands
class Mongo < Cartero::Command
	 def initialize
    super do |opts|
      opts.on("-s","--start",  
        "Start MongoDB") do |name|         
        @options.action = "start"
      end

      opts.on("-k","--stop",  
        "Stop MongoDB") do          
        @options.action = "stop"
      end

      opts.on("-r","--restart",  
        "Restart MongoDB") do          
        @options.action = "restart"
      end

      opts.on("-b", "--bind [HOST:PORT]", String,
        "Set MongoDB bind_ip and port") do |p|
        @options.mongodb = p
      end

    end
  end
  attr_accessor :mongo_ip
  attr_accessor :mongo_port

  def setup
    if @options.mongodb.nil?  
      @mongo_ip = "localhost"
      @mongo_port = "27017"
    else
      x = @options.mongodb.split(":")
      @mongo_ip = x[0]
      @mongo_port = x[1]
    end
  end

  def run
    case @options.action
    when "start"
      $stdout.puts "Launching mongodb"
      Cartero::DB.start(mongo_ip, mongo_port)
    when "stop"
      $stdout.puts "Stopping Mongodb"
      Cartero::DB.stop
    when "restart"
      $stdout.puts "Stopping Mongodb"
      Cartero::DB.stop
      sleep(1)
      $stdout.puts "Launching Mongodb"
      Cartero::DB.start
    else
      raise StandardError, "Unknown Action."
    end
  end
end
end
end
