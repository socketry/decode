# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

module TestModule
	# A test class demonstrating attribute type inference.
	class TestClass
		# Initialize a new test instance.
		def initialize(name, count)
			@name = name
			@count = count
			@data = {}
			@items = []
		end
		
		# The name of this instance.
		# @attribute [String] The name identifier.
		attr :name
		
		# The count value.
		# @attribute [Integer] A numeric counter.
		attr :count
		
		# Complex data storage.
		# @attribute [Hash(String, Object)] Mapping from keys to arbitrary values.
		attr :data
		
		# Collection of items.
		# @attribute [Array(String)] List of string items.
		attr :items
	end
	
	# A test module with attributes.
	module AttributeModule
		# Configuration settings.
		# @attribute [Hash(Symbol, String)] Configuration mapping.
		attr :settings
	end
end 
