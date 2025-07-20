# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "tag"

module Decode
	module Comment
		# Represents an RBS type annotation following rbs-inline syntax.
		#
		# Examples:
		# - `@rbs generic T` - Declares a generic type parameter for a class
		# - `@rbs [T] () { () -> T } -> Task[T]` - Complete method type signature
		#
		class RBS < Tag
			# Parse an RBS pragma from text.
			# @parameter directive [String] The directive name (should be "rbs").
			# @parameter text [String] The RBS type annotation text.
			# @parameter lines [Array(String)] The remaining lines (not used for RBS).
			# @parameter tags [Array(Tag)] The collection of tags.
			# @parameter level [Integer] The indentation level.
			def self.parse(directive, text, lines, tags, level = 0)
				self.build(directive, text)
			end
			
			# Build an RBS pragma from a directive and text.
			# @parameter directive [String] The directive name.
			# @parameter text [String] The RBS type annotation text.
			def self.build(directive, text)
				node = self.new(directive, text)
				return node
			end
			
			# Initialize a new RBS pragma.
			# @parameter directive [String] The directive name.
			# @parameter text [String?] The RBS type annotation text.
			def initialize(directive, text)
				super(directive)
				@text = text&.strip || ""
			end
			
			# The RBS type annotation text.
			# @attribute [String] The raw RBS text.
			attr :text
			
			# Check if this is a generic type declaration.
			# @returns [bool] True if this is a generic declaration.
			def generic?
				@text.start_with?("generic ")
			end
			
			# Extract the generic type parameter name.
			# @returns [String?] The generic type parameter name, or nil if not a generic.
			def generic_parameter
				if generic?
					# Extract the parameter name from "generic T" or "generic T, U"
					match = @text.match(/^generic\s+([A-Z][A-Za-z0-9_]*(?:\s*,\s*[A-Z][A-Za-z0-9_]*)*)/)
					return match[1] if match
				end
			end
			
			# Check if this is a method type signature.
			# @returns [bool] True if this is a method signature.
			def method_signature?
				@text && !generic?
			end
			
			# Get the method type signature text.
			# @returns [String?] The method signature text, or nil if not a method signature.
			def method_signature
				method_signature? ? @text : nil
			end
		end
	end
end
