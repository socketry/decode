# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "tag"

module Decode
	module Comment
		# Describes a block parameter.
		#
		# - `@yields {|person| ... } If a block is given.`
		#
		# Should contain nested parameters.
		class Yields < Tag
			# @constant [Regexp] Pattern for matching yields declarations.
			PATTERN = /\A(?<block>{.*?})(\s+(?<details>.*?))?\Z/
			
			# Build a yields tag from a directive and match.
			# @parameter directive [String] The directive name.
			# @parameter match [MatchData] The regex match data.
			def self.build(directive, match)
				block = match[:block] or raise "Missing block in yields match!"
				
				node = self.new(directive, block)
				
				if details = match[:details]
					node.add(Text.new(details))
				end
				
				return node
			end
			
			# Initialize a new yields tag.
			# @parameter directive [String] The directive name.
			# @parameter block [String] The block signature.
			def initialize(directive, block)
				super(directive)
				
				# @type ivar @block: String?
				@block = block
			end
			
			attr :block
		end
	end
end
