require 'rest-client'
require 'json'

module Cartero
# Documentation for BeefApi
class BeefApi
  #include CommandLineReporter

  class UnAuthenticated < StandardError
  end

  def initialize(options = {})
    @options = options
    @options[:username] ||= "beef"
    @options[:password] ||= "beef"
    @token = nil
  end

  attr_reader :token

  def client(path, opts={})
    RestClient::Resource.new(
      @options[:server] + path,
      {
        :timeout => 36000,
        :open_timeout => 36000
      }.merge(opts)
    )
  end

  def login
    begin
      tries ||=2
      @token = JSON.parse(client("/api/admin/login").post(
        {username: @options[:username], password: @options[:username] }.to_json,
        :content_type => :json, :accept => :json
      ))['token']
    rescue RestClient::RequestTimeout
      retry if (tries -= 1 ) > 0
    end
  end

  def hooks
    process_rest_call do
      client("/api/hooks").get(token_params)
    end
  end

  def hook(session)
    # RestApi Call to Beef Server
    process_rest_call do
      client("/api/hooks/#{session}").get(token_params)
    end
  end

  def logs
    # RestApi Call to Beef Server
    process_rest_call do
      client("/api/logs").get(token_params)
    end
  end

  def log(session)
    # RestApi Call to Beef Server
    process_rest_call do
      client("/api/logs/#{session}").get(token_params)
    end
  end

  def modules
    # RestApi Call to Beef Server
    process_rest_call do
      client("/api/modules").get(token_params)
    end
  end

  def module(id)
    # RestApi Call to Beef Server
    process_rest_call do
      client("/api/modules/#{id}").get(token_params)
    end
  end

  def command(session, id, parameters)
    # RestApi Call to Beef Server
    process_rest_call do
      client("/api/modules/#{session}/#{id}?#{token=@token}").post(
        parameters.to_json, :content_type => :json, :accept => :json
      )
    end
  end

  def command_result(session, id, cmd_id)
    # RestApi Call to Beef Server
    process_rest_call do
      client("/api/modules/#{session}/#{id}/#{cmd_id}").get(token_params)
    end
  end

  def multi_command(id, paramters = {}, mod_ids = [])
    # RestApi Call to Beef Server
    process_rest_call do
      client("/api/modules/multi_browser?#{token=@token}").post(
        {mod_id: id.to_i, mod_params: paramters, hb_ids: mod_ids}.to_json,
        :content_type => :json, :accept => :json
      )
    end
  end

  def dns_ruleset
    # RestApi Call to Beef Server
    process_rest_call do
      client("/api/dns/ruleset").get(token_params)
    end
  end

  def dns_rule(id)
    # RestApi Call to Beef Server
    process_rest_call do
      client("/api/dns/rule/#{id}").get(token_params)
    end
  end

  def dns_rule_remove(id)
    # RestApi Call to Beef Server
    process_rest_call do
      client("/api/dns/rule/#{id}").delete(token_params)
    end
  end

  private

  def token_params
    {:params => {:token => @token}}
  end

  def process_rest_call(&block)
    raise UnAuthenticated, "Null Token: Session must be established first." if @token.nil?
    # RestApi Call to Beef Server
    resp = block.call()
    # Case Statement to parse response depending on response code.
    case resp.code
    when 200
      JSON.parse(resp)
    when 403
      raise UnAuthenticated, "Unauthorized: A valid token must be provided."
    else
      raise StandardError, "Unknown: Something went wrong."
    end
  end
end
end
