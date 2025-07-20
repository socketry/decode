# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require_relative "parameter"

module Decode
	module Comment
		# Describes a method option (keyword argument).
		#
		# - `@option :cached [bool] Whether to cache the value.`
		#
		class Option < Parameter
		end
	end
end
