# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

module Decode
	module Syntax
		# Provides text rewriting functionality with match-based substitutions.
		class Rewriter
			# Initialize a new rewriter.
			# @parameter text [String] The text to rewrite.
			def initialize(text)
				@text = text
				@matches = []
			end
			
			# @attribute [String] The text to rewrite.
			attr :text
			
			# @attribute [Array[Match]] The matches to apply.
			attr :matches
			
			# Add a match to the rewriter.
			# @parameter match [Match] The match to add.
			def << match
				@matches << match
				return self
			end
			
			# Returns a chunk of raw text with no formatting.
			def text_for(range)
				@text[range] || ""
			end
			
			# Apply all matches to generate the rewritten output.
			# @parameter output [Array] The output array to append to.
			def apply(output = [])
				offset = 0
				
				@matches.sort.each do |match|
					if match.offset > offset
						output << text_for(offset...match.offset)
						
						offset = match.offset
					elsif match.offset < offset
						# Match intersects last output buffer.
						next
					end
					
					offset += match.apply(output, self)
				end
				
				if offset < @text.size
					output << text_for(offset...@text.size)
				end
				
				return output
			end
			
			# Generate a link to a definition.
			# @parameter definition [Definition] The definition to link to.
			# @parameter text [String] The text to display for the link.
			def link_to(definition, text)
				"[#{text}]"
			end
		end
	end
end
