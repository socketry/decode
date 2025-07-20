# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "tag"

module Decode
	# Represents comment parsing and processing functionality.
	module Comment
		# Describes an attribute type.
		#
		# - `@attribute [Integer] The person's age.`
		#
		class Attribute < Tag
			# @constant [Regexp] Pattern for matching attribute declarations.
			PATTERN = /\A\[#{Tag.bracketed_content(:type)}\](\s+(?<details>.*?))?\Z/
			
			# Build an attribute from a directive and match.
			# @parameter directive [String] The original directive text.
			# @parameter match [MatchData] The regex match data.
			def self.build(directive, match)
				type = match[:type] or raise "Missing type in attribute match!"
				
				node = self.new(directive, type)
				
				if details = match[:details]
					node.add(Text.new(details))
				end
				
				return node
			end
			
			# Initialize a new attribute.
			# @parameter directive [String] The original directive text.
			# @parameter type [String] The type of the attribute.
			def initialize(directive, type)
				super(directive)
				
				@type = type
			end
			
			# @attribute [String] The type of the attribute.
			attr :type
		end
	end
end
