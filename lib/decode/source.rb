# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "language"

module Decode
	# Represents a source file in a specific language.
	class Source
		# Initialize a new source file.
		# @parameter path [String] The file-system path to the source file.
		# @parameter language [Language::Generic] The language parser to use.
		def initialize(path, language)
			@path = path
			@language = language
			
			@buffer = nil
		end
		
		# The path of the source file.
		# @attribute [StringPath] A file-system path to the source file.
		attr :path
		
		# The language of the source file.
		# @attribute [Language::Generic] The language parser for this source.
		attr :language
		
		# Read the source file into an internal buffer/cache.
		# @returns [String] The contents of the source file.
		def read
			@buffer ||= File.read(@path).freeze
		end
		
		# Open the source file and read all definitions.
		# @yields {|definition| ...} All definitions from the source file.
		# 	@parameter definition [Definition]
		# @returns [Enumerator(Definition)] If no block given.
		def definitions(&block)
			return to_enum(:definitions) unless block_given?
			
			@language.definitions_for(self, &block)
		end
		
		# Open the source file and read all segments.
		# @yields {|segment| ...} All segments from the source file.
		# 	@parameter segment [Segment]
		# @returns [Enumerator(Segment)] If no block given.
		def segments(&block)
			return to_enum(:segments) unless block_given?
			
			@language.segments_for(self, &block)
		end
		
		# Generate code representation with optional index for link resolution.
		# @parameter index [Index?] Optional index for resolving links.
		# @parameter relative_to [Definition?] Optional definition to resolve relative references.
		# @returns [String] The formatted code representation.
		def code(index = nil, relative_to: nil)
			@language.code_for(self.read, index, relative_to: relative_to)
		end
	end
end
