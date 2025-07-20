# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "../../segment"

module Decode
	module Language
		module Ruby
			# A Ruby specific code segment.
			class Segment < Decode::Segment
				# Initialize a new Ruby segment.
				# @parameter comments [Array(String)] The comments for this segment.
				# @parameter language [Generic] The language instance.
				# @parameter node [Prism::Node] The syntax tree node.
				# @parameter options [Hash] Additional options.
				def initialize(comments, language, node, **options)
					super(comments, language, **options)
					
					@node = node
					@expression = node.location
				end
				
				# The parser syntax tree node.
				attr :node
				
				# Expand the segment to include another node.
				# @parameter node [Prism::Node] The node to include.
				def expand(node)
					@expression = @expression.join(node.location)
				end
				
				# The source code trailing the comments.
				# @returns [String?]
				def code
					@expression.slice
				end
			end
		end
	end
end
