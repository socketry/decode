# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

class Example
	# Forward all parameters to another method
	# @parameter args [Array] Any arguments
	# @parameter kwargs [Hash] Any keyword arguments 
	def forward(...)
		delegate(...)
	end
	
	# Another forwarding example with explicit return type
	# @returns [String] The result from the delegated method
	def forward_with_return(...)
		other_method(...)
	end
	
	private
	
	def delegate(*args, **kwargs)
		"delegated with #{args.length} args and #{kwargs.keys.length} kwargs"
	end
	
	def other_method(*args, **kwargs)
		"result"
	end
end 