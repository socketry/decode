# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2025, by Samuel Williams.

module Decode
	# Represents a location in a source file.
	class Location
		# Initialize a new location.
		# @parameter path [String] The path to the source file.
		# @parameter line [Integer] The line number in the source file.
		def initialize(path, line)
			@path = path
			@line = line
		end
		
		# @attribute [String] The path to the source file.
		attr :path
		
		# @attribute [Integer] The line number in the source file.
		attr :line
		
		# Generate a string representation of the location.
		def to_s
			"#{path}:#{line}"
		end
	end
end
