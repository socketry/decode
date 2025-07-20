# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

# A class demonstrating different method signatures.
class Calculator
	# Add two numbers.
	# @parameter a [Integer] The first number.
	# @parameter b [Integer] The second number.
	# @returns [Integer] The sum.
	def add(a, b)
		a + b
	end
	
	# Check if a number is positive.
	# @parameter num [Integer] The number to check.
	# @returns [bool] True if positive.
	def positive?(num)
		num > 0
	end
	
	# Initialize the calculator.
	def initialize
		@history = []
	end
	
	# Clear the history.
	def clear
		@history.clear
	end
	
	# Process numbers with a block.
	# @parameter numbers [Array(Integer)] The numbers to process.
	# @yields [Integer] Each number.
	# @returns [Array(Integer)] The processed numbers.
	def process_numbers(numbers, &block)
		numbers.map(&block)
	end
end
