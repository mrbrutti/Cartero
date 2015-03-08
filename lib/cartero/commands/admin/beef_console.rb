require 'command_line_reporter'

module Cartero
module Commands
# Documentation for AdminConsole < ::Cartero::Command
class BeefConsole < ::Cartero::Command
  include CommandLineReporter
  def initialize
    super(name: " Beef Administration Console",
          description: "Cartero Console based Admnistration Interface for Beef API. It allows users to interact with the captured data (i.e. hooks, logs, modules, commands, dns, etc.)",
          author: ['Matias P. Brutti <matias [©] section9labs.com>'],
          type: "Admin",
          license: "LGPL",
          references: [
            'https://section9labs.github.io/Cartero',
            'http://beefproject.com'
            ]
          ) do |opts|
      opts.on("--hooks [ALL|ONLINE|OFFLINE]", String,
        "Display the list of Beef Hooked Browsers") do |n|
        @options.hooks = n || "ALL"
      end

      opts.on("--hook SESSION", String,
        "Display a specific Beef hooked Session") do |s|
        @options.hook_session = s
      end

      opts.on("--logs [SESSION]", String,
        "Display Beef logs for all or a specific hooked Session") do |s|
        @options.logs = true
        @options.log_session = s
      end

      opts.on("--modules [ID]", String,
        "Display Beef logs for all or a specific hooked Session") do |id|
        @options.modules = true
        @options.module_id = id
      end

      opts.on("--dns-rules [ID]", String,
        "Display Beef logs for all or a specific hooked Session") do |id|
        @options.dns_rules = true
        @options.dns_rules_id = id
      end

      # TODO: Implement Command, Command-results, multi-command, dns-ruleset, dns-rule and dns-rule-remove
    end
  end

  def setup
    raise StandardError, "Missing {\"beef\" : {\"hook\" : \"VALUE\"} } in ~/.cartero/config"  if ::Cartero::GlobalConfig['beef']['hook'].nil? || ::Cartero::GlobalConfig['beef']['hook'] == ""
    setup_beef_rest_client
  end

  def run
    # Hooks
    run_hooks(@options.hooks) if @options.hooks
    run_hook(@options.hook_session) if @options.hook_session
    # Logs
    run_logs(@options.log_session) if @options.logs
    run_modules(@options.module_id) if @options.modules
    run_dns(@options.dns_rules_id) if @options.dns_rules
  end

  private

  def run_dns(id)
    if id.nil?
      dns_ruleset = @rest_client.dns_ruleset
      display_dns_ruleset(dns_ruleset)
    else
      rule = @rest_client.dns_rule(id)
      display_dns_rule(rule)
    end
  end

  def run_modules(id)
    if id.nil?
      modules = @rest_client.modules
      display_modules(modules)
    else
      mod = @rest_client.module(id)
      display_module(mod)
    end
  end

  def run_logs(session)
    if session.nil?
      logs = @rest_client.logs
    else
      logs = @rest_client.log(session)
    end
    display_logs(logs)
  end

  def run_hooks(c)
    hooked = @rest_client.hooks
    case c
    when /online/i
      display_hooks(hooked['hooked-browsers']['online'], 'ONLINE')
    when /offline/i
      display_hooks(hooked['hooked-browsers']['offline'], 'OFFLINE')
    when /all/i
      display_hooks(hooked['hooked-browsers']['online'], 'ONLINE')
      display_hooks(hooked['hooked-browsers']['offline'], 'OFFLINE')
    else
      raise StandardError, "Not a valid Option."
    end
  end

  def run_hook(session)
    info = @rest_client.hook(session)
    display_hook(info)
  end

  def display_dns_ruleset(ruleset)
    p ruleset
  end

  def display_dns_rule(rule)
    p rule
  end

  def display_module(mod)
    return if mod.empty?
    cols = Integer(`tput co`) - 166
    table() do
      row(:color => 'red', :header => true, :bold => true) do
        column('NAME', :width => 30)
        column('DESCRIPTION', :width => cols)
        column('CLASS', :width => 40)
        column('CATEGORY', :width => 40)
      end
      row(:color => 'blue') do
        column(mod['name'])
        column(mod['description'])
        column(mod['class'])
        column(mod['category'].is_a?(Array) ? mod['category'].join(', ') : mod['category'])
      end
    end
    if mod['options'].empty?
      puts 'No Options Available'
    else
      puts ""
      puts "OPTIONS"
      cols = (Integer(`tput co`) - 105) / 2
      table() do
        row(:color => 'red', :header => true, :bold => true) do
          column('LABEL', :width => 30)
          column('NAME', :width => 30)
          column('DESCRIPTION', :width => cols + 20)
          column('VALUE', :width => cols)
        end
        mod['options'].each do |x|
          row(:color => 'blue') do
            column(x['ui_label'])
            column(x['name'])
            column(x['description'])
            column(x['value'])
          end
        end
      end
    end
  end

  def display_modules(modules)
    return if modules.empty?
    table() do
      row(:color => 'red', :header => true, :bold => true) do
        column('ID', :width => 3)
        column('NAME', :width => 40)
        column('CLASS', :width => 40)
        column('CATEGORY', :width => 40)
      end
      modules.each do |_k,value|
        row(:color => 'blue') do
          column(value['id'].to_s)
          column(value['name'])
          column(value['class'])
          column(value['category'].is_a?(Array) ? value['category'].join(', ') : value['category'])
        end
      end
    end
  end

  def display_logs(logs)
    return if logs.empty?
    cols = Integer(`tput co`) - 48
    table() do
      row(:color => 'red', :header => true, :bold => true) do
        column('ID', :width => 3)
        column('DATE', :width => 25)
        column('TYPE', :width => 15)
        column('EVENT', :width => cols)
      end
      logs['logs'].each do |value|
        row(:color => 'blue') do
          column(value['id'].to_s)
          column(value['date'])
          column(value['type'])
          column(value['event'])
        end
      end
    end
  end

  def display_hooks(p,t)
    return if p.empty?
    puts t
    cols = Integer(`tput co`) - 182
    table() do
      row(:color => 'red', :header => true, :bold => true) do
        column('ID', :width => 3)
        column('IP', :width => 16)
        column('SESSION', :width => 80)
        column('NAME', :width => 15)
        column('VERSION', :width => 10)
        column('OS', :width => 15)
        column('PLATFORM', :width => 15)
        column('DOMAIN', :width => 10)
        column('PORT', :width => 6)
        column('PAGE_URI', :width => cols)
      end
      p.each do |key,value|
        row(:color => 'blue') do
          column(value['id'])
          column(value['ip'])
          column(value['session'])
          column(value['name'])
          column(value['version'])
          column(value['os'])
          column(value['platform'])
          column(value['domain'])
          column(value['port'])
          column(value['page_uri'])
        end
      end
    end
  end

  def display_hook(data)
    return if data.empty?
    cols = Integer(`tput co`) / 2
    table() do
      data.each do |key,value|
        row() do
          column(key, :color => 'red', :bold => true, :width => 20)
          column(value, :color => 'blue', :width => cols)
        end
      end
    end
  end

  def setup_beef_rest_client()
    require 'cartero/beef_api'
    @rest_client = ::Cartero::BeefApi.new(
      :server => ::Cartero::GlobalConfig['beef']['hook'],
      :username => @options.username || ::Cartero::GlobalConfig['beef']['username']  || "beef",
      :password => @options.password || ::Cartero::GlobalConfig['beef']['password']  || "beef"
    )
    @rest_client.login
    # Time to see if we were able to login.
    raise StandardError, "Something went wrong while connecting to Beef RESTful API" if @rest_client.token.nil?
  end
end
end
end
