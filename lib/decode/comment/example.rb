# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "tag"

module Decode
	module Comment
		# Represents a code example with an optional title.
		#
		# - `@example Title`
		# - `@example`
		#
		# Should contain nested text lines representing the example code.
		class Example < Tag
			# Parse an example directive from text.
			# @parameter directive [String] The directive name.
			# @parameter text [String?] The optional title text.
			# @parameter lines [Array(String)] The remaining lines.
			# @parameter tags [Tags] The tags parser.
			# @parameter level [Integer] The indentation level.
			def self.parse(directive, text, lines, tags, level = 0)
				node = self.new(directive, text)
				
				tags.parse(lines, level + 1) do |child|
					node.add(child)
				end
				
				return node
			end
			
			# Initialize a new example tag.
			# @parameter directive [String] The directive name.
			# @parameter title [String?] The optional title for the example.
			def initialize(directive, title = nil)
				super(directive)
				
				# @type ivar @title: String?
				@title = title&.strip unless title&.empty?
			end
			
			# @attribute [String?] The title of the example.
			attr :title
			
			# Get the example code as a single string with leading indentation removed.
			# @returns [String?] The example code joined with newlines, or nil if no code.
			def code
				lines = text
				return unless lines
				
				# Get the indentation from the first line
				if indentation = lines.first[/\A\s+/]
					# Remove the base indentation from all lines
					lines = lines.map{|line| line.sub(indentation, "")}
				end
				
				return lines.join("\n")
			end
		end
	end
end
