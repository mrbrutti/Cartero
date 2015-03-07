require 'shellwords'

module Cartero
module Commands
# Documentation for Templates < ::Cartero::Command
class Templates < ::Cartero::Command

  def initialize
    super(name: "Email Template Manager",
      description: "This command allows you to create and mantain customizeable templates for your campaings." +
                   "Even though it is not necessary to use this command to send templated emails, text, updates, " +
                   "it comes in handy when you have re-usable templates such as Social Network updates, Mail Server delivery, etc.",
      author: ["Matias P. Brutti <matias [©] section9labs.com>"],
      type:"Infrastructure",
      license: "LGPL",
      references: ["https://section9labs.github.io/Cartero"]
      ) do |opts|
      opts.on("-a","--add NAME", String,
        "Add Template") do |name|
        @options.name = name
        @options.action = "add"
      end

      opts.on("-e","--edit NAME", String,
        "Edit Template") do |name|
        @options.name = name
        @options.action = "edit"
      end

      opts.on("-d","--delete NAME", String,
        "Edit Template") do |name|
        @options.name = name
        @options.action = "delete"
      end

      opts.on("-l", "--list", String,
        "List Templates") do
        @options.action = "list"
      end
    end
  end

  def run
    case @options.action
    when /add/
      Templates.create(@options.name)
      $stdout.puts "Template #{@options.name} Created."
    when /edit/
      Templates.edit(@options.name)
      $stdout.puts "Template #{@options.name} Edited."
    when /delete/
      Templates.edit(@options.name)
      $stdout.puts "Template #{@options.name} Deleted."
    when /list/
      Templates.list.each do |s|
        $stdout.puts "    " + s
      end
    end
  end

  def self.list
    templates = []
    Dir.glob(::Cartero::TemplatesDir + "/**/*.erb").each do |template|
      templates << File.basename(template).split(".")[0..-2].join(".")
    end
    templates
  end

  def self.exists?(name)
    File.exist?(self.template(name))
  end

  def self.template(name)
    templates = Dir.glob(base_templates)
    templates.concat(Dir.glob(::Cartero::TemplatesDir + "/**/*.erb"))
    template_file = templates.detect { |tmplt| tmplt =~ /^#{name}.erb$/ }
    template_file || "#{Cartero::TemplatesDir}/#{name}.erb"
  end

  def self.base_templates
    "#{File.dirname(__FILE__)}/../../../templates/mail/**/*.erb"
  end

  def self.create(name)
    if self.exists?(name)
      raise StandardError, "Server with name (#{name}) already exists"
    else
      Kernel.system("$EDITOR #{template(name.shellescape)}")
    end
  end

  def self.edit(name)
    if !self.exists?(name)
      raise StandardError, "Server with name #{name} does not exist"
    else
      server = template(name.shellescape)
      Kernel.system("cp #{template} #{server}")
      Kernel.system("$EDITOR #{server}")
    end
  end

  def self.delete(name)
    if !self.exists?(name)
      raise StandardError, "Server with name #{name} does not exist"
    else
      Kernel.system("rm #{template(name.shellescape)}")
    end
  end
end
end
end
