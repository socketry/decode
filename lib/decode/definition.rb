# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "location"

module Decode
	# A symbol with attached documentation.
	class Definition
		# Initialize the symbol.
		# @parameter path [Symbol | Array(Symbol)] The path of the definition relatve to the parent.
		# @parameter parent [Symbol] The parent lexical scope.
		# @parameter language [Language] The language in which the symbol is defined in.
		# @parameter comments [Array(String)] The comments associated with the definition.
		# @parameter source [Source] The source file containing this definition.
		def initialize(path, parent: nil, language: parent&.language, comments: nil, visibility: :public, source: parent&.source)
			@path = Array(path).map(&:to_sym)
			
			@parent = parent
			@language = language
			@source = source
			
			@comments = comments
			@visibility = visibility
			
			@full_path = nil
			@qualified_name = nil
			@nested_name = nil
		end
		
		# Generate a debug representation of the definition.
		def inspect
			"\#<#{self.class} #{qualified_name}>"
		end
		
		# Generate a string representation of the definition.
		alias to_s inspect
		
		# The symbol name.
		# e.g. `:Decode`.
		# @attribute [Symbol]
		def name
			@path.last
		end
		
		# @attribute [Array(Symbol)] The path to the definition, relative to the parent.
		attr :path
		
		# The full path to the definition.
		def full_path
			@full_path ||= begin
				if @parent
					@parent.full_path + @path
				else
					@path
				end
			end
		end
		
		# The lexical path to the definition (full path including all namespaces).
		# @returns [Array(Symbol)] The complete path from root to this definition.
		alias lexical_path full_path
		
		# @attribute [Definition | Nil] The parent definition, defining lexical scope.
		attr :parent
		
		# @attribute [Language::Generic] The language the symbol is defined within.
		attr :language
		
		# @attribute [Source | Nil] The source file containing this definition.
		attr :source
		
		# @attribute [Array(String)] The comment lines which directly preceeded the definition.
		attr :comments
		
		# Whether the definition is considered part of the public interface.
		# This is used to determine whether the definition should be documented for coverage purposes.
		# @returns [Boolean] True if the definition is public.
		def public?
			true
		end
		
		# Whether the definition has documentation.
		# @returns [Boolean] True if the definition has non-empty comments.
		def documented?
			@comments&.any?
		end
		
		# The qualified name is an absolute name which includes any and all namespacing.
		# @returns [String]
		def qualified_name
			@qualified_name ||= begin
				if @parent
					[@parent.qualified_name, self.nested_name].join("::")
				else
					self.nested_name
				end
			end
		end
		
		# The name relative to the parent.
		# @returns [String]
		def nested_name
			@nested_name ||= "#{@path.join("::")}"
		end
		
		# Does the definition name match the specified prefix?
		# @parameter prefix [String] The prefix to match against.
		# @returns [Boolean]
		def start_with?(prefix)
			self.nested_name.start_with?(prefix)
		end
		
		# Convert this definition into another kind of definition.
		# @parameter kind [Symbol] The kind to convert to.
		def convert(kind)
			raise ArgumentError, "Unable to convert #{self} into #{kind}!"
		end
		
		# A short form of the definition.
		# e.g. `def short_form`.
		#
		# @returns [String | Nil]
		def short_form
		end
		
		# A long form of the definition.
		# e.g. `def initialize(kind, name, comments, **options)`.
		#
		# @returns [String | Nil]
		def long_form
			self.short_form
		end
		
		# A long form which uses the qualified name if possible.
		# Defaults to {long_form}.
		#
		# @returns [String | Nil]
		def qualified_form
			self.long_form
		end
		
		# Whether the definition spans multiple lines.
		#
		# @returns [Boolean]
		def multiline?
			false
		end
		
		# The full text of the definition.
		#
		# @returns [String | Nil]
		def text
		end
		
		# Whether this definition can contain nested definitions.
		#
		# @returns [Boolean]
		def container?
			false
		end
		
		# Whether this represents a single entity to be documented (along with it's contents).
		#
		# @returns [Boolean]
		def nested?
			container?
		end
		
		# Structured access to the definitions comments.
		#
		# @returns [Documentation | Nil] A {Documentation} instance if this definition has comments.
		def documentation
			if @comments&.any?
				@documentation ||= Documentation.new(@comments, @language)
			end
		end
		
		# The location of the definition.
		#
		# @returns [Location | Nil] A {Location} instance if this definition has a location.
		def location
			nil
		end
		
		# The visibility of the definition.
		# @attribute [Symbol] :public, :private, :protected
		attr_accessor :visibility
	end
end
