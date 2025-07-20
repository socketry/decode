# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "rbs"

module Decode
	module RBS
		# Base wrapper class for RBS generation from definitions.
		class Wrapper
			# Initialize the wrapper instance variables.
			# @parameter definition [Definition] The definition to wrap.
			def initialize(definition)
				@definition = definition
				@tags = nil
				@comment = nil
			end
			
			# Extract RBS tags from the definition's documentation.
			# @returns [Array<Comment::RBS>] The RBS tags found in the documentation.
			def tags
				@tags ||= extract_tags
			end
			
			# Extract comment from the definition's documentation.
			# @returns [RBS::AST::Comment?] The RBS comment object.
			def comment
				@comment ||= extract_comment
			end
			
			private
			
			# Extract RBS tags from the definition's documentation.
			# @returns [Array<Comment::RBS>] The RBS tags found in the documentation.
			def extract_tags
				@definition.documentation&.children&.select do |child|
					child.is_a?(Comment::RBS)
				end || []
			end
			
			# Extract comment from definition documentation.
			# @parameter definition [Definition] The definition to extract comment from (defaults to @definition).
			# @returns [RBS::AST::Comment?] The extracted comment or nil if no documentation.
			def extract_comment(definition = @definition)
				documentation = definition.documentation
				return nil unless documentation
				
				# Extract the main description text (non-tag content)
				comment_lines = [] #: Array[String]
				
				documentation.children&.each do |child|
					if child.is_a?(Decode::Comment::Text)
						comment_lines << child.line.strip
					elsif !child.is_a?(Decode::Comment::Tag)
						# Handle other text-like nodes
						comment_lines << child.to_s.strip if child.respond_to?(:to_s)
					end
				end
				
				# Join lines with newlines to preserve markdown formatting
				unless comment_lines.empty?
					comment_text = comment_lines.join("\n").strip
					return ::RBS::AST::Comment.new(string: comment_text, location: nil) unless comment_text.empty?
				end
				
				nil
			end
		end
	end
end
