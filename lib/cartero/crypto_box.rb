#encoding: utf-8
require "base64"
require "json"
require "cgi"

module Cartero
# Documentation for CryptoBox
# This is a module container with setup method to determine which Encryption
# algorithm Cartero should be using.
module CryptoBox
  def self.setup
    if ::Cartero::GlobalConfig["crypto"] =~ /AES/i
      require 'openssl'
      require 'digest'
      require 'cartero/crypto/aes'
    else
      require 'rbnacl/libsodium'
      require 'rbnacl'
      require 'cartero/crypto/rbnacl'
    end
  end
end
end
