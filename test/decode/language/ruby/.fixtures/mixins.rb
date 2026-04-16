# frozen_string_literal: true

module Mixins
	module Greeting
		def hello
			"hello"
		end
	end
	
	class Greeter
		include Greeting
		extend Greeting
		prepend Greeting
	end
end
