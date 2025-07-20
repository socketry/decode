# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

module Decode
	module Language
		# An reference which can be resolved to zero or more definitions.
		class Reference
			# Initialize the reference.
			# @parameter identifier [String] The identifier part of the reference.
			# @parameter language [Language::Generic] The language this reference belongs to.
			# @parameter lexical_path [Array(String)?] The lexical path scope for resolution.
			def initialize(identifier, language, lexical_path = nil)
				@identifier = identifier
				@language = language
				
				@lexical_path = lexical_path
				@path = nil
			end
			
			# Generate a string representation of the reference.
			def to_s
				"{#{self.language} #{self.identifier}}"
			end
			
			# Generate a debug representation of the reference.
			def inspect
				"\#<#{self.class} {#{self.identifier}}>"
			end
			
			# @attribute [String] The identifier part of the reference.
			attr :identifier
			
			# @attribute [Language::Generic] The language associated with this reference.
			attr :language
			
			# Whether the reference starts at the base of the lexical tree.
			def absolute?
				!self.relative?
			end
			
			# Check if this is a relative reference.
			def relative?
				prefix, name = self.lexical_path.first
				
				return prefix.nil?
			end
			
			# Split an identifier into prefix and name components.
			# @parameter identifier [String] The identifier to split.
			def split(identifier)
				identifier.scan(/(\W+)?(\w+)/)
			end
			
			# Get the lexical path of this reference.
			def lexical_path
				@lexical_path ||= self.split(@identifier)
			end
			
			# Calculate the priority of a definition for matching.
			# @parameter definition [String] The definition to check.
			# @parameter prefix [String] The prefix to match against.
			def priority(definition, prefix)
				if prefix.nil?
					return 1
				elsif definition.start_with?(prefix)
					return 0
				else
					return 2
				end
			end
			
			# Find the best matching definition from a list.
			# @parameter definitions [Array(Definition)] The definitions to choose from.
			# @returns [Definition?] The best matching definition, if any.
			def best(definitions)
				prefix, name = lexical_path.last
				
				first = nil #: Definition?
				without_prefix = nil #: Definition?
				
				definitions.each do |definition|
					first ||= definition
					
					next unless definition.language == @language
					
					if prefix.nil?
						without_prefix ||= definition
					elsif definition.start_with?(prefix)
						return definition
					end
				end
				
				return without_prefix || first
			end
			
			# The lexical path of the reference.
			# @returns [Array(Symbol)]
			def path
				@path ||= self.lexical_path.map{|_, name| name.to_sym}
			end
		end
	end
end
