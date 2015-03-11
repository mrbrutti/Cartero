#encoding: utf-8
module Cartero
# Documentation for CryptoBox - AES Implementation
module CryptoBox
  ALGORITHM = "aes-256-cbc"
  @@key = nil
  @@iv = nil
  @@secret_box = nil

  def self.init
    if !key.nil? && !iv.nil? && !secret_box.nil?
      return true
    elsif File.exist?(Cartero::SecretMaterial)
      # Read data from JSON File
      m = JSON.parse(File.read(::Cartero::SecretMaterial),{:symbolize_names => true})
      self.secret_box = OpenSSL::Cipher::Cipher.new(ALGORITHM)
      self.key        = Base64.decode64(m[:key])
      self.nonce 			= Base64.decode64(m[:nonce]).strip
    else
      @@secret_box = OpenSSL::Cipher::Cipher.new(ALGORITHM)
      @@key = Digest::SHA512.hexdigest(@@secret_box.random_key)
      @@iv=  @@secret_box.random_iv
    end
    true
  end

  def self.reinit
    File.delete(::Cartero::SecretMaterial)
    init
  end

  def self.encrypt(m)
    secret_box.encrypt
    secret_box.key = key
    secret_box.iv = iv
    e = secret_box.update(m)
    e << secret_box.final
    Base64.strict_encode64(e).strip.gsub("+","-").gsub("/","_")
  end

  def self.decrypt(e)
    secret_box.decrypt
    secret_box.key = key
    secret_box.iv = iv
    d = secret_box.update(
      Base64.strict_decode64(
        e.gsub("-","+").gsub("_","/")
      ).strip
    )
    d << secret_box.final
  end

  def self.close
    self.key = nil
    self.nonce = nil
    self.secret_box = nil
  end

  class << self
    private

    def key
      @@key
    end

    def iv
      @@nonce
    end

    def nonce
      iv
    end

    def secret_box
      @@secret_box
    end

    def key=(k)
      @@key = k
    end

    def iv=(n)
      @@iv = n
    end

    def nonce=(n)
      @@iv = n
    end

    def secret_box=(s)
      @@secret_box = s
    end
  end
end
end
