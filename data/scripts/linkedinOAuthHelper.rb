
# modified version of https://github.com/hexgnu/linkedin/blob/master/EXAMPLES.md by Abhishek shah

require 'linkedin'
require 'json'

#  api keys, also known as client_id (api_access) and client_secret (api_secret) 
**MUST CHANGE TO YOUR ANOTHER DEVELOPER ACCOUNT FOR LINKEDIN
# get your api keys at https://www.linkedin.com/secure/developer
api_access = ''
api_secret = ''

# login into linked in as a developer
client = LinkedIn::Client.new(api_access, api_secret)

# If you want to use one of the scopes from linkedin you have to pass it in at this point
# You can learn more about it here: http://developer.linkedin.com/documents/authentication
request_token = client.request_token({}, :scope => "rw_company_admin w_share r_basicprofile r_emailaddress")

rtoken = request_token.token
rsecret = request_token.secret

# to test from your desktop, open the following url in your browser
# and record the pin it gives you
puts request_token.authorize_url

puts "Please go to the website above and input the pin into the console"

pin = gets.chomp.to_i
puts "OAuth Token is first, OAuth Secret is second"
oauth_token, oauth_secret = client.authorize_from_request(rtoken, rsecret, pin)

puts oauth_token
puts oauth_secret 
puts
puts client.profile

serverConfig = {"name"=> "linkedin","type"=> "linkedin","options"=> {
	  "api_access"=> api_access,
	  "api_secret"=> api_secret,
	  "oauth_token"=> oauth_token,
	  "oauth_secret"=> oauth_secret   
	} }  
	
puts serverConfig.to_json
puts "\n\nwrote the above data to the linkedin JSON file\n\n"
File.write('/root/.cartero/servers/linkedin.json', serverConfig.to_json)

