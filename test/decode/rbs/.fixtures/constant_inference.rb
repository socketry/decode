# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

module TestModule
	# A test class demonstrating constant type inference.
	class TestClass
		# @constant [String] The default configuration file path.
		CONFIG_FILE = "config/settings.yaml"
		
		# @constant [Integer] The maximum number of retries allowed.
		MAX_RETRIES = 3
		
		# @constant [Hash(Symbol, String)] Default configuration values.
		DEFAULT_CONFIG = {
			host: "localhost",
			port: "3000",
			env: "development"
		}
		
		# @constant [Array(String)] List of supported file formats.
		SUPPORTED_FORMATS = ["json", "yaml", "toml"]
		
		# @constant [String | Integer?] A union type constant.
		FLEXIBLE_VALUE = nil
		
		# Regular constant without type annotation - should be ignored
		REGULAR_CONSTANT = "no_type_annotation"
	end
	
	# A test module with constants.
	module ConfigModule
		# @constant [Integer] The default timeout in seconds.
		DEFAULT_TIMEOUT = 30
		
		# @constant [bool] Whether debug mode is enabled by default.
		DEBUG_MODE = false
		
		# @constant [Regexp] Pattern for validating identifiers.
		IDENTIFIER_PATTERN = /\A[a-z][a-z0-9_]*\z/i
	end
end 