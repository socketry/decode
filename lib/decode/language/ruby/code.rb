# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "definition"
require_relative "../../syntax/link"

require "prism"

module Decode
	module Language
		module Ruby
			# A Ruby-specific block of code.
			class Code
				# Initialize a new code block.
				# @parameter text [String] The code text.
				# @parameter index [Index] The index to use.
				# @parameter relative_to [Definition?] The definition this code is relative to.
				# @parameter language [Language::Generic] The language of the code.
				def initialize(text, index, relative_to: nil, language:)
					@text = text
					@root = ::Prism.parse(text)
					@index = index
					@relative_to = relative_to
					@language = language
				end
				
				# @attribute [String] The code text.
				attr :text
				
				# @attribute [untyped] The parsed syntax tree.
				attr :root
				
				# @attribute [Index] The index to use for lookups.
				attr :index
				
				# @attribute [Definition?] The definition this code is relative to.
				attr :relative_to
				
				# @attribute [Language::Generic] The language of the code.
				attr :language
				
				# Extract definitions from the code.
				# @parameter into [Array] The array to extract definitions into.
				# @returns [Array] The array with extracted definitions.
				def extract(into = [])
					if @index
						traverse(@root.value, into)
					end
					
					return into
				end
				
				private
				
				# Traverse the syntax tree and extract definitions.
				# @parameter node [untyped] The syntax tree node to traverse.
				# @parameter into [Array] The array to extract definitions into.
				# @returns [self]
				def traverse(node, into)
					case node&.type
					when :program_node
						traverse(node.statements, into)
					when :call_node
						if reference = Reference.from_const(node, @language)
							if definition = @index.lookup(reference, relative_to: @relative_to)
								# Use message_loc for the method name, not the entire call
								expression = node.message_loc
								range = expression.start_offset...expression.end_offset
								into << Syntax::Link.new(range, definition)
							end
						end
						
						# Extract constants from arguments:
						if node.arguments
							node.arguments.arguments.each do |argument_node|
								traverse(argument_node, into)
							end
						end
					when :constant_read_node
						if reference = Reference.from_const(node, @language)
							if definition = @index.lookup(reference, relative_to: @relative_to)
								expression = node.location
								range = expression.start_offset...expression.end_offset
								into << Syntax::Link.new(range, definition)
							end
						end
					when :statements_node
						node.body.each do |child|
							traverse(child, into)
						end
					end
					
					return self
				end
			end
		end
	end
end
