# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "comment/node"

require_relative "comment/tags"
require_relative "comment/attribute"
require_relative "comment/constant"
require_relative "comment/parameter"
require_relative "comment/option"
require_relative "comment/pragma"
require_relative "comment/raises"
require_relative "comment/returns"
require_relative "comment/throws"
require_relative "comment/yields"

module Decode
	# Structured access to a set of comment lines.
	class Documentation < Comment::Node
		# Initialize the documentation with an array of comments, within a specific language.
		#
		# @parameter comments [Array(String)] An array of comment lines.
		# @parameter language [Language::Generic?] The language in which the comments were extracted.
		def initialize(comments, language)
			super(nil)
			
			@comments = comments
			@language = language
			
			if language
				language.tags.parse(@comments.dup) do |node|
					self.add(node)
				end
			end
		end
		
		# @attribute [Array(String)] The underlying comments from which the documentation is extracted.
		attr :comments
		
		# @attribute [Language::Generic?] The language in which the documentation was extracted from.
		attr :language
	end
end
