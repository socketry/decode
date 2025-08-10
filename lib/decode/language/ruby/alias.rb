# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "definition"

module Decode
	module Language
		module Ruby
			# Represents an alias statement, e.g., `alias new_name old_name` or `alias_method :new_name, :old_name`
			class Alias < Definition
				# Initialize a new alias definition.
				# @parameter new_name [String] The new name for the alias.
				# @parameter old_name [String] The original name being aliased.
				# @parameter options [Hash] Additional options for the definition.
				def initialize(new_name, old_name, **options)
					super(new_name, **options)
					@old_name = old_name
				end
				
				attr :old_name
				
				# Aliases don't require separate documentation as they reference existing methods.
				# @returns [bool] Always false for aliases.
				def coverage_relevant?
					false
				end
				
				# Generate a short form representation of the alias.
				def short_form
					"alias #{self.name} #{@old_name}"
				end
				
				# Generate a long form representation of the alias.
				def long_form
					"alias #{self.name} #{@old_name}"
				end
				
				# Generate a string representation of the alias.
				def to_s
					"#{self.class.name} #{self.name} -> #{@old_name}"
				end
			end
		end
	end
end
