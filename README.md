![Mail](http://icons.iconarchive.com/icons/simiographics/mixed/128/MailBox-icon.png)
# Cartero

### Description
A simple Phishing Framework Library with a CLI tool. The project was born out of necessity on projects. Even though there are many projects out there, we were not able to find a suitable solution that gave us both easy of use and customizability.

Cartero is a modular


### Installation

#### Dependencies
```shell
❯❯❯ brew install mongodb
```

#### Framework
```shell
❯❯❯ git clone github.com/section9labs/Cartero
❯❯❯ cd Cartero
❯❯❯ gem install bundle
❯❯❯ bundle install
❯❯❯ cd bin
```

### Usage
### Commands
Cartero is a very simple to use CLI.

```shell
❯❯❯ ./cartero
Usage: cartero [options]

List of Commands:
    AdminConsole, Mailer, Cloner, Listener, Servers, Templates

Global options:
        --proxy [HOST:PORT]          Sets TCPSocket Proxy server
    -c, --config [CONFIG_FILE]       Provide a different cartero config file
    -v, --[no-]verbose               Run verbosely
    -p [PORT_1,PORT_2,..,PORT_N],    Global Flag fo Mailer and Webserver ports
        --ports
    -m, --mongodb [HOST:PORT]        Global Flag fo Mailer and Webserver ports
    -d, --debug                      Sets debug flag on/off
        --editor [EDITOR]            Edit Server
        --list-commands              Prints list of commands for bash completion

Common options:
    -h, --help [COMMAND]             Show this message
        --version                    Shows cartero CLI version

```

### Basic Commands

#### Cloner
A simple WebSite Cloner. It allows us to download and convert a website into a Cartero WebServer application.
In this way we can easily customize the website to Harvest Credentials, Server Payloads, or create a fully customized website.

```shell
❯❯❯ ./cartero Cloner
Usage: Cartero Cloner [options]
    -U, --url [URL_PATH]             Full Path of site to clone
    -W, --webserver [SERVER_NAME]    Sets WebServer name to use
    -p, --path [PATH]                Sets path to save webserver
    -P, --payload [PAYLOAD_PATH]     Sets payload path
        --wget                       Use wget to clone url
        --apache                     Generate Apache Proxy conf
    -h, --help                       Show this message
```
By default the command users our own internal system to download and convert links to render, but we also support a *--wget* option that will use wget system command.

#### Listener
The listener is the system responsible of running the WebServer created through Cloner or manually. By default we also have a very simple WebServer if none is provided.

```shell
❯❯❯ ./cartero Listener
Usage: Cartero Listener [options]
    -i, --ip [1.1.1.1]               Sets IP interface, default is 0.0.0.0
    -p [PORT_1,PORT_2,..,PORT_N],    Sets Email Payload Ports to scan
        --ports
    -s, --ssl                        Run over SSL. [this also requires --sslcert and --sslkey]
    -C, --sslcert [CERT_PATH]        Sets Email Payload Ports to scan
    -K, --sslkey [KEY_PATH]          Sets SSL key to use for Listener.
    -V, --views [VIEWS]              Sets SSL Certificate to use for Listener.
    -P, --public [PUBLIC_FOLDER]     Sets a Sinatra public_folder
        --payload [PAYLOAD]          Sets a payload download to serve on /download
        --customapp [CUSTOM_SINATRA] Sets a custom Sinatra::Base WebApp. Important, WebApp name should be camelized of filename
    -h, --help                       Show this message
```
The WebServers support ssl keys, different public and view paths. Additionally the servers can also be hosted on multiple ports at the same time and they can be bind to a specific IP address as well.

#### Servers
In order to send emails campaigns we need to setup servers. This is a command that would help Cartero to create, store and list servers. All data is stored on .cartero configuration directory.

```shell
❯❯❯ ./cartero Servers

Usage: Cartero Servers [options]
    -a, --add [NAME]                 Add Server
    -e, --edit [NAME]                Edit Server
    -d, --delete [NAME]              Edit Server
    -l, --list                       List servers
    -h, --help                       Show this message
```

#### Templates
Just like Servers, email campaigns also need to send a body or html body. This will allow you to keep track, create, list and edit templates being used for each email. It is worth noting that this are not necessary to use and the Mailer command takes direct path to emails templates as well.

```shell
❯❯❯ ./cartero Templates
Usage: Cartero Templates [options]
    -a, --add [NAME]                 Add Template
    -e, --edit [NAME]                Edit Template
    -d, --delete [NAME]              Edit Template
    -l, --list                       List Templates
    -h, --help                       Show this message
```
#### Mailer
This is the main command and component in our Framework. Mailer allows Cartero users to send custom templated emails to one or more email addresses.
Each email can be customized using the powerful erb Template engine, allowing users to create complex programming within the templates and send massive, but yet very targeted emails.
For more information on how to build custom templates, please refer to our Examples.

```shell
❯❯❯ ./cartero Mailer
Usage: Cartero Mailer [options]
    -D, --data [DATA_FILE]           File containing template data sets
    -S, --server [SERVER_NAME]       Sets Email server to use
    -s, --subject [EMAIL_SUBJECT]    Sets Email subject
    -f, --from [EMAIL_FROM]          Sets Email from
    -r, --reply-to [EMAIL_REPLY_TO]  Sets Email from
    -b, --body [FILE_PATH]           Sets Email Text Body
    -B, --htmlbody [FILE_PATH]       Sets Email HTML Body
    -c, --charset [CHARSET]          Sets Email charset
    -C [CONTENT_TYPE],               Sets Email content type
        --content-type
    -a [FILE_1,FILE_2,..,FILE_N],    Sets Email Attachments
        --attachment
    -p [PORT_1,PORT_2,..,PORT_N],    Sets Email Payload Ports to scan
        --ports
    -h, --help                       Show this message
```

#### AdminConsole
The Admin Console is a simple WebApplication that allow us list information about each Campaign.

```shell
❯❯❯ ./cartero AdminConsole
Usage: Cartero AdminConsole [options]
    -i, --ip [1.1.1.1]               Sets IP interface, default is 0.0.0.0
    -p [PORT_1,PORT_2,..,PORT_N],    Sets Email Payload Ports to scan
        --ports
    -s, --ssl                        Run over SSL. [this also requires --sslcert and --sslkey]
    -C, --sslcert [CERT_PATH]        Sets Email Payload Ports to scan
    -K, --sslkey [KEY_PATH]          Sets Email Payload Ports to scan
    -h, --help                       Show this message
```
### Building Commands

Commands have a fairly easy infrastructure. Default Framework commands are stored on _Cartero/lib/cartero/commands/*.rb_ and _~/.cartero/commands/*.rb_.

```ruby
module Cartero
module Commands
class CommandName < Cartero::Command
	def initialize
		super do |opts|
			opts.on("-x", "--xoption [DATA_FILE]", String,
    		"Description of command option") do |data|
      	@options.xoption = data
    	end
      opts.on("-y", "--yoption [DATA_FILE]", String,
        "Description of command option") do |data|
        @options.xoption = data
      end
      # help() option already provided.
    end
  end

  def setup
    # This will be hooked and run before run().
    # It is meant as a method so the commands can run everything before that.
  end

  def run
    # Everything that will run.
  end

  def after
    # This is the place to run clean-up code.
  end
end
end
end
```


### Mailer Templates
Emails are simple txt files or limited HTML files, depending on the type of format being used. Cartero allows to build and tempaltes both formats. In order to allow complex templating we use erb ruby gem, also used in many projects like Sinatra, Rails, etc.

Files can be extremely customized given erb allows for programatically edits on run time. Additionally we add an encrypted self[:payload] to each email template that allows Cartero to indentify each specific entity regardless. Last, but not least, this payload is encrypted using a key that is randomly generated and only exists on the Cartero config directory, allowing attackers to keep data secure and away from detection. 

**SAMPLE DATA FILE**
```json
[{
    "email": "matiasbrutti@gmail.com",
    "name": "Matias Brutti"
}, {
    "email": "gauchitohill@gmail.com",
    "name": "Gauchito Hill"
}, {
    "email": "matias@section9labs.com",
    "name": "Matias Brutti - section9labs"
}, {
    "email": "matiasbrutti@hotmail.com",
    "name": "Matias Brutti - Hotmail",
    "subject": "Hotmail Test 123"
}]
```
**HTML SAMPLE TEMPLATE**
```html
<html>
<body>
<h3> Hello Spear Phishing World <%= self[:name] %>,</h3>
<p> This is an automated email to your email <%= self[:email] %>.<p>
<% if self[:ports] %>
	<% self[:ports].each do |port| %>
	    <img alt="" width="1" height="1" border="0" style="height:1px !important;width:1px !important;border-width:0 !important;margin-top:0 !important;margin-bottom:0 !important;margin-right:0 !important;margin-left:0 !important;padding-top:0 !important;padding-bottom:0 !important;padding-right:0 !important;padding-left:0 !important;" src="http://localhost:<%= port %>/image?key=<%= self[:payload] %>">
	<% end %>
<% end %>
</body>
</html>

```

**TEXT SAMPLE TEMPLATE**
```txt
Hola <%= self[:name] %>,
This email needs to be displayed as HTML.
This is an automated email to your email<%= self[:email] %>.
In addition, this email can also be displayed securely
on http://192.168.1.216:8080/click?key=<%= self[:payload] %>

cheers,

<%= self[:from_name] %>

```

### Servers
Servers can be managed using the Cartero Servers command, which allows to add, edit and delete servers.
Additionally, anyone can easily create them manually and store them in _~/.cartero/servers/*.json_


```json
{
    "name": "gmail",
    "type": "smtp",
    "options": {
        "address": "smtp.yourserver.com",
        "port": 25,
        "user_name": "user",
        "password": "password",
        "authentication": "plain",
        "domain": "localhost.localdomain"
    }
}
```

### TODO
Coding:
- Add attack payloads to Cloner
- Evaluate/Add tracking methods.

Documentation:
- Add Samples to each Command Section
- Upload Videos
