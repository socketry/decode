# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "reference"
require_relative "../documentation"

module Decode
	module Language
		# Represents a generic language implementation that can be extended for specific languages.
		class Generic
			EXTENSIONS = []
			
			TAGS = Comment::Tags.build do |tags|
				tags["attribute"] = Comment::Attribute
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
			end
			
			# Initialize a new generic language.
			# @parameter name [String] The name of the language.
			# @parameter extensions [Array(String)] File extensions for this language.
			# @parameter tags [Comment::Tags] The comment tags to recognize.
			def initialize(name, extensions: self.class::EXTENSIONS, tags: self.class::TAGS)
				@name = name
				@extensions = extensions
				@tags = tags
			end
			
			# The name of this language.
			# @attribute [String] The language name.
			attr :name
			
			# Get all names for this language.
			# @returns [Array(String)] An array containing the language name.
			def names
				[@name]
			end
			
			# The file extensions this language supports.
			# @attribute [Array(String)] The supported file extensions.
			attr :extensions
			
			# The comment tags this language recognizes.
			# @attribute [Comment::Tags] The tag definitions.
			attr :tags
			
			# Generate a language-specific reference.
			# @parameter identifier [String] A valid identifier for this language.
			# @returns [Reference] A reference object for the given identifier.
			def reference_for(identifier)
				Reference.new(identifier, self)
			end
			
			# Get the parser for this language.
			# @returns [untyped] The parser instance, or nil if not available.
			def parser
				nil
			end
			
			# Parse the input yielding definitions.
			# @parameter source [Source] The input source file which contains the source code.
			# @yields {|definition| ...} Receives the definitions extracted from the source code.
			# 	@parameter definition [Definition] The source code definition including methods, classes, etc.
			# @returns [Enumerator(Segment)] If no block given.
			def definitions_for(source, &block)
				if parser = self.parser
					parser.definitions_for(source, &block)
				end
			end
			
			# Parse the input yielding segments.
			# Segments are constructed from a block of top level comments followed by a block of code.
			# @parameter source [Source] The input source file which contains the source code.
			# @yields {|segment| ...}
			# 	@parameter segment [Segment]
			# @returns [Enumerator(Segment)] If no block given.
			def segments_for(source, &block)
				if parser = self.parser
					parser.segments_for(source, &block)
				end
			end
			
			# Generate a code representation with syntax highlighting and link resolution.
			# @parameter text [String] The source code text to format.
			# @parameter index [Index] The index for resolving references.
			# @parameter relative_to [Definition] The definition to resolve relative references from.
			# @returns [untyped] A formatted code object with syntax highlighting.
			def code_for(text, index, relative_to: nil)
				raise NotImplementedError, "Code generation is not implemented for #{self.class}!"
			end
		end
	end
end
