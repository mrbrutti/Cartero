require 'command_line_reporter'

module Cartero
module Commands
class LinkedIn < ::Cartero::Command
  include CommandLineReporter
  def initialize
    super do |opts|
      opts.on("-D", "--data [DATA_FILE]", String,
        "File containing template data sets") do |data|
        @options.data = data
      end

      opts.on("-S", "--server [SERVER_NAME]", String,
        "Sets Email server to use") do |server|
        @options.server = server
      end

      opts.on("-s", "--subject [MESSAGE_SUBJECT]", String,
        "Sets LinkedIn Message subject") do |subject|
        @options.subject = subject
      end

      opts.on("-b", "--body [FILE_PATH]", String,
        "Sets LinkedIn Message Body") do |body|
        @options.body = body
      end

      opts.on("-l", "--list [CONNECTIONS|GROUPS]", [:connections, :groups],
              "List json of (connections or groups)") do |t|
        @options.list = t
      end

      opts.on("--send [MESSAGE|GROUP_UPDATE|UPDATE]", [:message, :group, :update],
              "Send one or more (message/s or group/s updates)") do |t|
        @options.send_type = t
      end

      opts.on("-o", "--save [FILE_PATH]", String,
        "Save content to file") do |f|
        @options.file_save = f
      end

      opts.on("--json", "Sets output to json") do
        @options.json = true
      end
    end
  end

  attr_reader :data
  attr_reader :server
  attr_reader :from
  attr_reader :subject
  attr_reader :charset
  attr_reader :body
  attr_accessor :file_save
  attr_accessor :client

  def setup
    require 'erb'
    require 'linkedin'
    require 'json'
    require 'multi_json'

    if @options.data.nil? and @options.list.nil? and @options.send_type.to_s != "update"
      raise StandardError, "A data set [--data] must be provided"
    end

    if @options.body.nil? and @options.list.nil?
      raise StandardError, "A body [--body] must be provided"
    end

    if @options.server.nil?
      raise StandardError, "A Linkedin Server Credentials should be provided."
    elsif !Cartero::Commands::Servers.exists?(@options.server)
      raise StandardError, "Server with name #{@options.server} does not exist."
    else
      s = ::Cartero::Commands::Servers.server(@options.server)
      @server = JSON.parse(File.read(s),{:symbolize_names => true})

      if @server[:type].downcase != "linkedin"
        raise StandardError, "Server with name #{@options.server} is not linkedin type."
      end

    end

    unless @options.data.nil?
      @data = JSON.parse(File.read(File.expand_path @options.data),{:symbolize_names => true})
    end

    @from 				= @options.from
    @subject 			= @options.subject
    @file_save    = @options.file_save

    unless @options.body.nil?
      if ::Cartero::Commands::Templates.exists?(@options.body)
        @body = File.read("#{Cartero::TemplatesDir}/#{@options.body}.erb")
      else
        if File.exist?(File.expand_path @options.body)
          @body = File.read(File.expand_path @options.body)
        else
          raise StandardError, "Text Body Template (#{File.expand_path @options.body}) does not exists"
        end
      end
    end
    login
  end

  def run
    if !@options.list.nil?
      list = [];
      case @options.list
      when /connections/
        @client.connections.all.map.each do |p|
          unless p.id == "private"
            list << { "id" => p.id, "name" => p.first_name, "last" => p.last_name, "title" => p.headline }
          end
        end
      when /groups/
        @client.group_memberships.all.map.each do |g|
          list << { "id" => g.id, "name" => g.group.name }
        end
      end
      if @options.json
        print_json(list)
      else
        display_table(list, @options.list)
      end
    else
      if @options.send_type == :update
        _response = @client.add_share(:comment => body)
        puts "Sending Linkedin Status Update #{@client.profile.first_name} #{@client.profile.last_name}."
        return
      end
      send do |s|
        puts "Sending Linkedin Message to #{s[:name]} #{s[:last]}\n\tStatus: #{s[:status]}"
      end
    end
  end


  def login
    @client = ::LinkedIn::Client.new(server[:options][:api_access], server[:options][:api_secret])
    @client.authorize_from_access server[:options][:oauth_token], server[:options][:oauth_secret]
  end

  def send
    data.each do |entity|
      if !entity[:id].nil?
        begin
        _r = create_linkedin_message(entity, @options.send_type || "message")
        rescue StandardError => e
          entity[:status] = e
        end
        yield entity if block_given?
      else
        Cartelo::Log.error "Entity #{entity} does not contain an :email key."
      end
    end
  end

  def create_linkedin_message(entity, type)
    mail = {}

    # set TO, FROM and Subject
    mail[:to] 			= entity[:id]
    mail[:title]	= entity[:subject] 	|| subject

    # Add Text body if was provided.
    unless body.nil?
      entity[:payload] = ::Cartero::CryptoBox.encrypt(entity.to_json)
      mail[:summary] = ERB.new(body).result(entity.get_binding)
    end

    case type
    when /message/ then
      response = @client.send_message(mail[:title], mail[:summary], [mail[:to]])
    when /group/ then
      mail[:content] = entity[:content] || {}
      response = @client.add_group_share(mail[:to], mail)
    end
    response
  end

  def display_table(h, type)
    return if h.empty?
    case type
    when /connections/
      table() do
        row(:color => 'red', :header => true, :bold => true) do
          column('ID', 		:width => 15)
          column('NAME',  :width => 20)
          column('LAST',	:width => 20)
          column('TITLE', :width => 90)
        end
        h.each do |con|
          row() do
            column(con["id"], :color => 'blue')
            column(con["name"])
            column(con["last"])
            column(con["title"])
          end
        end
      end
    when /groups/
       table() do
        row(:color => 'red', :header => true, :bold => true) do
          column('ID', 		:width => 10)
          column('NAME',  :width => 70)
        end
        h.each_with_index do |con|
          row() do
            column(con["id"], :color => 'blue')
            column(con["name"])
          end
        end
      end
    end
  end

  def print_json(list)
    unless file_save.nil?
      $stdout.puts "Saving data to file #{file_save}."
      f = File.new(file_save , "w+")
      f.puts JSON.pretty_generate list
      f.close
    else
      $stdout.puts JSON.pretty_generate list
    end
  end
end
end
end
