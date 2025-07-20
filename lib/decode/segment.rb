# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "documentation"

module Decode
	# A chunk of code with an optional preceeding comment block.
	#
	#	~~~ ruby
	#	# Get the first segment from a source file:
	#	segment = source.segments.first
	#	~~~
	#
	class Segment
		# Initialize a new segment.
		# @parameter comments [Array(String)] The preceeding comments.
		# @parameter language [Language::Generic] The language of the code.
		def initialize(comments, language)
			@comments = comments
			@language = language
			@documentation = nil
		end
		
		# @attribute [Array(String)] The preceeding comments.
		attr :comments
		
		# @attribute [Language::Generic] The language of the code attached to this segment.
		attr :language
		
		# An interface for accsssing the documentation of the definition.
		# @returns [Documentation?] A {Documentation} instance if this definition has comments.
		def documentation
			if @comments&.any?
				@documentation ||= Documentation.new(@comments, @language)
			end
		end
		
		# The source code trailing the comments.
		# @returns [String?]
		def code
		end
	end
end
