# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "tag"

module Decode
	module Comment
		# Represents a named method parameter.
		#
		# - `@parameter age [Float] The users age.`
		#
		class Parameter < Tag
			# @constant [Regexp] Pattern for matching parameter declarations.
			PATTERN = /\A(?<name>.*?)\s+\[#{Tag.bracketed_content(:type)}\](\s+(?<details>.*?))?\Z/
			
			# Build a parameter from a directive and regex match.
			# @parameter directive [String] The original directive text.
			# @parameter match [MatchData] The regex match data containing name, type, and details.
			# @returns [Parameter] A new parameter object.
			def self.build(directive, match)
				name = match[:name] or raise ArgumentError, "Missing name in parameter match!"
				type = match[:type] or raise ArgumentError, "Missing type in parameter match!"
				
				node = self.new(directive, name, type)
				
				if details = match[:details]
					node.add(Text.new(details))
				end
				
				return node
			end
			
			# Initialize a new parameter.
			# @parameter directive [String] The original directive text.
			# @parameter name [String] The name of the parameter.
			# @parameter type [String] The type of the parameter.
			def initialize(directive, name, type)
				super(directive)
				
				@name = name
				@type = type
			end
			
			# @attribute [String] The name of the parameter.
			attr :name
			
			# @attribute [String] The type of the parameter.
			attr :type
		end
	end
end
