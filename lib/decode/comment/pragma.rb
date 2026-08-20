# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "tag"

module Decode
	module Comment
		# Asserts a specific property about the method signature.
		#
		# - `@reentrant This method is thread-safe.`
		# - ``@deprecated Please use ruby:`other_method` instead.``
		# - `@blocking This method may block.`
		# - `@asynchronous This method may yield.`
		#
		class Pragma < Tag
			# Parse a pragma directive from text.
			# @parameter directive [String] The directive name.
			# @parameter text [String] The directive text.
			# @parameter lines [Array(String)] The remaining lines.
			# @parameter tags [Array(Tag)] The collection of tags.
			# @parameter level [Integer] The indentation level.
			def self.parse(directive, text, lines, tags, level = 0)
				self.build(directive, text)
			end
			
			# Build a pragma from a directive and text.
			# @parameter directive [String] The directive name.
			# @parameter text [String] The directive text.
			def self.build(directive, text)
				node = self.new(directive)
				
				if text
					node.add(Text.new(text))
				end
				
				return node
			end
			
			# Initialize a new pragma.
			# @parameter directive [String] The directive name.
			def initialize(directive)
				super(directive)
			end
		end
	end
end
