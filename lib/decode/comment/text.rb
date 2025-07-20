# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "node"

module Decode
	module Comment
		# A structured comment.
		class Text
			# Initialize a new text node.
			# @parameter line [String] The text content.
			def initialize(line)
				@line = line
			end
			
			# @attribute [String] The text content.
			attr :line
			
			# Traverse the text node.
			def traverse
			end
		end
	end
end
