#encoding: utf-8
module Cartero
  # Documentation for UserAgentParser
  class UserAgentParser
    def initialize(ua)
      @ua = ua
    end

    attr_reader :ua, :comp, :os, :browser, :engine, :platform, :lang
    def parse
      @comp = parse_comp
      @os = parse_os
      @browser = parse_browser
      @engine = parse_engine
      @platform = parse_platform
      @lang = parse_lang
      true
    end

    private

    def parse_comp
      case @ua
      when /mozilla\/(\d+)[._](\d+)/i then "Mozilla #{$1}.#{$2}"
      when /Microsoft Office\/(\d+)[._](\d+)/i   then
        "Microsoft Office #{$1}"
      else
        "unknown"
      end
    end

    def parse_os
      case @ua
      when /windows nt 6\.3/i     then  'Windows 8.1'
      when /windows nt 6\.2/i     then  'Windows 8'
      when /windows nt 6\.0/i     then  'Windows Vista'
      when /windows nt 6\.\d+/i   then  'Windows 7'
      when /windows nt 5\.2/i     then  'Windows 2003'
      when /windows nt 5\.1/i     then  'Windows XP'
      when /windows nt 5\.0/i     then  'Windows 2000'
      when /windows\-nt/i         then  'Windows'
      when /os x (\d+)[._](\d+)[._]*(\d+)*/i      then  "OS X #{$1}.#{$2}#{if $3 !=nil; '.' + $3; end}"
      when /Android (\d+)[._](\d+)[._]*(\d+)*/i   then  "Android #{$1}.#{$2}#{if $3 !=nil; '.' + $3; end}"
      when /iphone OS (\d+)[._](\d+)[._]*(\d+)*/i then  "iPhone #{$1}.#{$2}#{if $3 !=nil; '.' + $3; end}"
      when /iPad; CPU OS (\d+)[._](\d+)[._]*(\d+)*/i then "iPad iOS #{$1}.#{$2}#{if $3 !=nil; '.' + $3; end}"
      when /wii/i                 then  'Wii'
      when /playstation 3/i       then  'Playstation'
      when /playstation portable/i then 'Playstation'
      when /linux/i               then  'Linux'
      else
        'Unknown'
      end
    end

    def parse_engine
      case @ua
      when /version\/(\d+(:?\.\d+)*)\s*safari/i  then "Safari #{$1}"
      when /firefox\/((:?[0-9]+\.)+[0-9]+)/i then "Firefox #{$1}"
      when /mozilla\/[0-9]+\.[0-9] \(compatible; msie ([0-9]+\.[0-9]+)/ then "IE #{$1}"
      when /webkit\/([\d\w\.\-]+)/i   then "webkit #{$1}"
      when /khtml/i                   then "khtml"
      when /konqueror/i               then "konqueror"
      when /chrome\/([\d\w\.\-]+)/i   then "Chrome #{$1}"
      when /presto/i                  then "presto"
      when /gecko\/([\d\w\.\-]+)/i    then "gecko #{$1}"
      when /trident\/([\d\w\.\-]+)/i  then "Trident #{$1}"
      when /msoffice 12/              then "Microsoft_Word 12"
      when /msoffice 14/              then "Microsoft_Word 14"
      when /blackberry/               then "Mango"
      else
        'Unknown'
      end
    end

    def parse_platform
      case @ua
      when /Android/i then
        @ua.scan(/\(Linux;(.*)\) /).to_s.split("\)")[0].split(";")[-1]
      when /Intel Mac OS X/i        then "Intel Mac OS X"
      when /Machintosh PPC/i        then "PPC Mac OS X"
      when /iphone OS/i             then "iPhone, iPad or iPod"
      when /ipad/                   then "iPad"
      when /windows nt/i            then  @ua.scan(/x64/) == 0 ? "Generic x86 32-bit PC" : "Generic x86 64-bit PC"
      when /blackberry([\d\w\.\-]+)/i then "BlackBerry"
      when /wii/i                   then "Wii"
      when /playstation 3/i         then "Playstation"
      when /playstation portable/i  then "Playstation Portable"
      else
        'Unknown'
      end
    end

    def parse_lang
      case @ua
      when /en-us/ then "English - United States"
      when /es-ar/ then "Spanish - Argentina"
      when /es-es/ then "Spanish - Spain"
      when /es-la/ then "Spanish - Latin America"
      else
        'Unknown'
      end
    end

    def parse_browser
      case @ua
      when /explorer/i then "Internet Explorer"
      when /chrome\/([\d\w\.\-]+)/i  then "Chrome #{$1}"
      when /firefox\/([\d\w\.\-]+)/i then "Firefox #{$1}"
      when /safari\/([\d\w\.\-]+)/i  then "Safari #{$1}"
      when /webkit\/([\d\w\.\-]+)/i  then "Webkit #{$1}"
      when /AppleWebKit\/([\d\w\.\-]+)/i then "Apple Webkit #{$1}"
      when /msie\s([\d\w.\-]+)/i   then "Internet Explorer #{$1}"
      when /outlook ([\d\w\.\-]+)/i  then "Microsoft Outlook 2010 #{$1}"
      when /msoffice 12/  then "Microsoft Outlook 2007"
      when /msoffice 14/  then "Microsoft Outlook 2010"
      when /Thunderbird\/([\d\w\.\-]+)/i then "Thunderbird #{$1}"
      when /lotus\-notes\/(\d+)[._](\d+)[._]*(\d+)*/i then
        "Lotus Notes #{$1}.#{$2}#{if $3 !=nil; '.' + $3; end}"
      else
        'Unknown'
      end
    end
  end
end
