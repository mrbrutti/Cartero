#encoding: utf-8
require 'optparse'
require 'ostruct'

module Cartero
  # Documentation for Command
  # Base Command class container with several shared methods definitions.
  class Command
    @@disable_override = false
    attr_accessor :options
    attr_accessor :args
    attr_accessor :information

    def initialize(i={}, &block)
      @information = i || {}
      @options = OpenStruct.new
      @options.commands 		= []

      parse(&block)
    end

    def setup
    end

    def after
    end

    def help
      @parser.help
    end

    def order!
      @parser.order!
    end

    def name
      self.class.name.split("::")[-1]
    end

    def parse(&block)
      @parser = OptionParser.new do |opts|
        opts.banner = "Usage: Cartero #{name} [options]"

        block.call(opts)

        opts.separator ""
        opts.separator "Common options:"

        opts.on("-h", "--help", "Show this message") do
          puts @parser
          exit
        end

        opts.on("--details", "Show command details") do
          unless information.empty?
            require 'cartero/command_helpers'
            CommandHelpers.new.generate_table(information, "#{self.class.name.gsub('::','/')}")
          end
          exit
        end

        opts.on("--list-options", "Show list of available options") do
          $stdout.puts "--" + @parser.send(:top).long.map {|x| x[0]}.join(" --")
          exit
        end

        opts.on("--list-short-options", "Show list of short available options") do
          $stdout.puts @parser.send(:top).long.map {|x| x[1].short[0]}.join(" ")
          exit
        end
      end
    end

    def self.method_added name
      unless @@disable_override
        if name == :run
          @@disable_override = true # to stop the new build method
          self.send :alias_method, :sub_run, :run
          self.send :remove_method, :run
          self.send :define_method, :run do
            setup
            sub_run
            after
          end
          @@disable_override = false
        end
      end
    end
  end
end

module Cartero
  # Documentation for Command
  # Base Payload class container. This is just a wrapper for Command.
  # In the future we might spin the class as its own if Payloads
  # differ a lot from  Command. For the time being it is just naming.
  class Payload < ::Cartero::Command
  end
end
