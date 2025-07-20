# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require_relative "definition"

module Decode
	# An abstract namespace for nesting definitions.
	class Scope < Definition
		# @returns [String] The name of the scope.
		def short_form
			name.to_s
		end
		
		# Scopes are always containers.
		# @returns [bool] Always `true`.
		def container?
			true
		end
	end
end
