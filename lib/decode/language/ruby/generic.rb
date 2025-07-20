# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require_relative "reference"
require_relative "parser"
require_relative "code"

require_relative "../generic"
require_relative "../../comment/rbs"

module Decode
	module Language
		module Ruby
			# Represents the Ruby language implementation for parsing and analysis.
			class Generic < Language::Generic
				EXTENSIONS = [".rb", ".ru"]
				
				TAGS = Comment::Tags.build do |tags|
					tags["attribute"] = Comment::Attribute
					tags["constant"] = Comment::Constant
					tags["parameter"] = Comment::Parameter
					tags["option"] = Comment::Option
					tags["yields"] = Comment::Yields
					tags["returns"] = Comment::Returns
					tags["raises"] = Comment::Raises
					tags["throws"] = Comment::Throws
					
					tags["deprecated"] = Comment::Pragma
					
					tags["asynchronous"] = Comment::Pragma
					
					tags["public"] = Comment::Pragma
					tags["private"] = Comment::Pragma
					
					tags["rbs"] = Comment::RBS
				end
				
				# Get the parser for Ruby source code.
				# @returns [Language::Ruby::Parser] The Ruby parser instance.
				def parser
					@parser ||= Parser.new(self)
				end
				
				# Generate a language-specific reference for Ruby.
				# @parameter identifier [String] A valid Ruby identifier.
				# @returns [Reference] A Ruby-specific reference object.
				def reference_for(identifier)
					Reference.new(identifier, self)
				end
				
				# Generate a code representation with syntax highlighting and link resolution.
				# @parameter text [String] The source code text to format.
				# @parameter index [Index] The index for resolving references.
				# @parameter relative_to [Definition] The definition to resolve relative references from.
				# @returns [Code] A formatted code object with syntax highlighting.
				def code_for(text, index, relative_to: nil)
					Code.new(text, index, relative_to: relative_to, language: self)
				end
			end
		end
	end
end
