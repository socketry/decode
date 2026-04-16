# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

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
