require 'puma'
require 'puma/cli'

module Puma
	class CarteroCLI < Puma::CLI

		def initialize(argv)
			Cartero::DB.start
			super(argv)
		end

    def stop
      Cartero::DB.stop
      super
    end

    def graceful_stop
      Cartero::DB.stop
      super
    end
	end
end
