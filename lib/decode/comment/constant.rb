# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "tag"
require_relative "text"

module Decode
	module Comment
		# Represents a constant type declaration.
		#
		# - `@constant [Regexp] Pattern for matching parameters.`
		#
		class Constant < Tag
			# @constant [Regexp] Pattern for matching constant declarations.
			PATTERN = /\A\[#{Tag.bracketed_content(:type)}\](\s+(?<details>.*?))?\Z/
			
			# Build a constant from a directive and regex match.
			# @parameter directive [String] The original directive text.
			# @parameter match [MatchData] The regex match data containing type and details.
			# @returns [Constant] A new constant object.
			def self.build(directive, match)
				type = match[:type] or raise "Missing type in constant match!"
				
				node = self.new(directive, type)
				
				if details = match[:details]
					node.add(Text.new(details))
				end
				
				return node
			end
			
			# Initialize a new constant.
			# @parameter directive [String] The directive that generated the tag.
			# @parameter type [String] The type of the constant.
			def initialize(directive, type)
				super(directive)
				@type = type
			end
			
			# @attribute [String] The type of the constant.
			attr :type
		end
	end
end 