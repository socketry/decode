# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "../../definition"

module Decode
	module Language
		module Ruby
			# Represents a Ruby-specific definition extracted from source code.
			class Definition < Decode::Definition
				# Initialize the definition from the syntax tree node.
				# @parameter arguments [Array] Arguments passed to the parent class.
				# @parameter visibility [Symbol] The visibility of the definition (:public, :private, :protected).
				# @parameter node [Parser::AST::Node] The syntax tree node representing this definition.
				# @parameter options [Hash] Additional options passed to the parent class.
				def initialize(*arguments, visibility: nil, node: nil, **options)
					super(*arguments, **options)
					
					@visibility = visibility
					@node = node
				end
				
				# The parser syntax tree node.
				# @attribute [Parser::AST::Node] The AST node representing this definition.
				attr :node
				
				# The visibility of the definition.
				# @attribute [Symbol] The visibility level (:public, :private, or :protected).
				attr_accessor :visibility
				
				# Check if this definition is public.
				# @returns [bool] True if the definition is public.
				def public?
					@visibility == :public
				end
				
				# Check if this definition is protected.
				# @returns [bool] True if the definition is protected.
				def protected?
					@visibility == :protected
				end
				
				# Check if this definition is private.
				# @returns [bool] True if the definition is private.
				def private?
					@visibility == :private
				end
				
				# Check if this definition spans multiple lines.
				# @returns [bool] True if the definition spans multiple lines.
				def multiline?
					@node.location.start_line != @node.location.end_line
				end
				
				# The source code associated with the definition.
				# @returns [String]
				def text
					location = @node.location
					source_text = location.slice_lines
					lines = source_text.split("\n")
					
					if lines.count == 1
						return lines.first
					else
						# Get the indentation from the first line of the node in the original source
						if indentation = source_text[/\A\s+/]
							# Remove the base indentation from all lines
							lines.each{|line| line.sub!(indentation, "")}
						end
						
						return lines.join("\n")
					end
				end
				
				# Get the location of this definition.
				# @returns [Location?] The location object if source is available.
				def location
					if @source and location = @node&.location
						Location.new(@source.path, location.start_line)
					end
				end
			end
		end
	end
end
