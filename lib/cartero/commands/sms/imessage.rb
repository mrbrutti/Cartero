module Cartero
module Commands
class IMessage < ::Cartero::Command
  def initialize
    super do |opts|

      opts.separator "IMPORTANT: This command only works on OSX"
      opts.separator ""

      opts.on("-D", "--data DATA_FILE", String,
        "File containing template data sets") do |data|
        @options.data = data
      end

      opts.on("-A", "--attachment ATTACHMENT", String,
        "Sets iMessage file path to send") do |attachment|
        @options.attachment = attachment
      end

      opts.on("-b", "--body BODY_FILE", String,
        "Sets iMessage message") do |body|
        @options.body = body
      end

      opts.on("-m", "--message MESSAGE", String,
        "Sets iMessage message") do |message|
        @options.message = message
      end
    end
  end

  def setup

    if @options.data.nil?
      raise StandardError, "A data set [--data] must be provided"
    end

    if @options.body.nil? && @options.message.nil? && @options.attachment.nil?
      raise StandardError, "At least a body [--body], a message [--message] and/or attachment [--attachment] must be provided"
    end

    unless @options.data.nil?
      @data = JSON.parse(File.read(File.expand_path @options.data),{:symbolize_names => true})
    end

    unless @options.message.nil?
      @message = @options.message
    end

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

    unless @options.attachment.nil?
      if File.exist?(File.expand_path @options.attachment)
        @attachment = File.expand_path @options.attachment
      else
        raise StandardError, "Attachment (#{File.expand_path @options.attachment}) does not exists"
      end
    end
  end

  attr_reader :attachment
  attr_reader :data
  attr_reader :body
  attr_reader :message

  def send
    data.each do |entity|
      if !entity[:email].nil? || !entity[:phone].nil?
        yield entity if block_given?
        create_imessage(entity)
      else
        Cartelo::Log.error "Entity #{entity} does not contain an :email key."
      end
    end
  end

  def run
    if RUBY_PLATFORM =~ /darwin/i
      send do |s|
        puts "Sending iMessage to #{s[:email] || s[:phone]}"
      end
    else
      raise StandardError, "Platform not supported. Only works in Mac OSX."
    end
  end

  def create_imessage(entity)
    mail = {}

    mail[:to] = entity[:email] || entity[:phone]

    unless entity[:message].nil? && body.nil?
      entity[:payload] = ::Cartero::CryptoBox.encrypt(entity.to_json)
      mail[:body] = entity[:message] || ERB.new(body).result(entity.get_binding)
      mail[:type] = "message"
      send_msg(mail)
    end

    unless message.nil?
      entity[:payload] = ::Cartero::CryptoBox.encrypt(entity.to_json)
      mail[:body] = ERB.new(message).result(entity.get_binding)
      mail[:type] = "message"
      send_msg(mail)
    end

    unless entity[:attachment].nil? && attachment.nil?
      mail[:body] = entity[:attachment] || attachment
      mail[:type] = "attachment"
      send_msg(mail)
    end
  end

  def send_msg(m)
    system("osascript #{File.expand_path(File.dirname(__FILE__) + "/../../../../data/scripts/imsg.applescript")} #{m[:to]} #{m[:type]} \"#{m[:body]}\"")
  end

end
end
end
