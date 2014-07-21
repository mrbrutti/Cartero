require "rbnacl/libsodium"
require "rbnacl"
require "base64"
require "json"
require "cgi"

module Cartero
	class CryptoBox
		@@key = nil
		@@nonce = nil
		@@secret_box = nil

		def self.init
			if !key.nil? && !nonce.nil? && !secret_box.nil?
				# Things are already loaded. No need to read or dump.
				return true
			elsif File.exist?(Cartero::SecretMaterial)
				# Read data from JSON File
				m = JSON.parse(File.read(Cartero::SecretMaterial),{:symbolize_names => true})
				self.key 				= Base64.decode64(m[:key])
				self.secret_box = RbNaCl::SecretBox.new(key)
				self.nonce 			= Base64.decode64(m[:nonce]).strip
			else
				# Generate new file & Keys
				self.key 				= RbNaCl::Random.random_bytes(RbNaCl::SecretBox.key_bytes)
				self.secret_box = RbNaCl::SecretBox.new(key)
				self.nonce 			= RbNaCl::Random.random_bytes(secret_box.nonce_bytes)
				# Storing keys on file.
				f = File.new(Cartero::SecretMaterial, "w+")
				f.puts({ 
					:key => Base64.strict_encode64(key).strip, 
					:nonce => Base64.strict_encode64(nonce).strip 
					}.to_json
				)
				f.close
			end
			true
		end

		def self.reinit
			File.delete(Cartero::SecretMaterial)
			init
		end

		def self.encrypt(message)
			Base64.strict_encode64(secret_box.encrypt(nonce, message)).strip.gsub("+","-").gsub("/","_")
		end

		def self.decrypt(ciphertext)
			secret_box.decrypt(nonce, Base64.strict_decode64(ciphertext.gsub("-","+").gsub("_","/")).strip)
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

			def nonce
				@@nonce
			end

			def 	secret_box
				@@secret_box
			end

			def key=(k)
				@@key = k
			end

			def nonce=(n)
				@@nonce = n
			end

			def secret_box=(s)
				@@secret_box = s
			end
		end
	end
end