# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "rbs"
require "console"

module Decode
	module RBS
		# Utilities for working with RBS types.
		module Type
			# Check if an RBS type represents a nullable/optional type
			# This method recursively traverses the type tree to find nil anywhere
			# @parameter rbs_type [untyped] The RBS type to check for nullability.
			# @returns [bool] True if the type can be nil, false otherwise.
			def self.nullable?(rbs_type)
				case rbs_type
				when ::RBS::Types::Optional
					# Type? form - directly optional
					true
				when ::RBS::Types::Union
					# Type | nil form - recursively check all union members
					rbs_type.types.any? {|type| nullable?(type)}
				when ::RBS::Types::Tuple
					# [Type] form - recursively check all tuple elements
					rbs_type.types.any? {|type| nullable?(type)}
				when ::RBS::Types::Bases::Nil
					# Direct nil type
					true
				else
					false
				end
			end
			
			# Parse a type string and convert it to RBS type
			# @parameter type_string [String] The type string to parse.
			# @returns [untyped] The parsed RBS type object.
			def self.parse(type_string)
				# This is for backwards compatibility with the old syntax, eventually we will emit warnings for these:
				type_string = type_string.tr("()", "[]")
				type_string.gsub!(/\s*\| Nil/, "?")
				type_string.gsub!("Boolean", "bool")
				
				return ::RBS::Parser.parse_type(type_string)
			rescue => error
				warn("Failed to parse type string: #{type_string}") if $DEBUG
				return ::RBS::Parser.parse_type("untyped")
			end
		end
	end
end 