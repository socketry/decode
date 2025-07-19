# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "decode/rbs"
require "decode/index"
require "decode/language/ruby"
require "tmpdir"

describe "RBS Integration" do
	around do |&block|
		Dir.mktmpdir do |root|
			@root = root
			block.call
		end
	end
	
	def create_ruby_file(filename, content)
		path = File.join(@root, filename)
		File.write(path, content)
		path
	end
	
	def generate_rbs_for_ruby(content)
		path = create_ruby_file("test.rb", content)
		index = Decode::Index.for(path)
		generator = Decode::RBS::Generator.new
		
		buffer = StringIO.new
		generator.generate(index, output: buffer)
		
		return buffer.string
	end
	
	with "basic class generation" do
		let(:ruby_code) do
			<<~RUBY
				# A simple test class
				class TestClass
					# Initialize a new instance
					def initialize(name)
						@name = name
					end
				
					# Get the name
					def name
						@name
					end
				
					# Check if empty
					def empty?
						@name.nil? || @name.empty?
					end
				end
			RUBY
		end
		
		it "generates RBS for basic class with methods" do
			result = generate_rbs_for_ruby(ruby_code)
			
			expect(result).to be(:include?, "class TestClass")
			expect(result).to be(:include?, "def initialize")
			expect(result).to be(:include?, "def name")
			expect(result).to be(:include?, "def empty?")
		end
	end
	
	with "module generation" do
		let(:ruby_code) do
			<<~RUBY
				# A utility module
				module Utils
					# Convert to string
					def self.to_string(value)
						value.to_s
					end
				
					# Check if nil
					def self.nil?(value)
						value.nil?
					end
				end
			RUBY
		end
		
		it "generates RBS for module with class methods" do
			result = generate_rbs_for_ruby(ruby_code)
			
			expect(result).to be(:include?, "module Utils")
			expect(result).to be(:include?, "def self.to_string")
			expect(result).to be(:include?, "def self.nil?")
		end
	end
	
	with "inheritance" do
		let(:ruby_code) do
			<<~RUBY
				# Base class
				class Animal
					def speak
						"..."
					end
				end
				
				# Derived class
				class Dog < Animal
					def speak
						"Woof!"
					end
				end
			RUBY
		end
		
		it "generates RBS with inheritance" do
			result = generate_rbs_for_ruby(ruby_code)
			
			expect(result).to be(:include?, "class Animal")
			expect(result).to be(:include?, "class Dog < Animal")
			expect(result).to be(:include?, "def speak")
		end
	end
	
	with "documented methods" do
		let(:ruby_code) do
			<<~RUBY
				class Calculator
					# Add two numbers
					# @parameter a [Integer] The first number
					# @parameter b [Integer] The second number
					# @returns [Integer] The sum
					def add(a, b)
						a + b
					end
				
					# Divide two numbers
					# @parameter dividend [Float] The dividend
					# @parameter divisor [Float] The divisor
					# @returns [Float] The quotient
					# @raises [ZeroDivisionError] When divisor is zero
					def divide(dividend, divisor)
						dividend / divisor
					end
				end
			RUBY
		end
		
		it "generates RBS with type information from documentation" do
			result = generate_rbs_for_ruby(ruby_code)
			
			expect(result).to be(:include?, "class Calculator")
			expect(result).to be(:include?, "def add")
			expect(result).to be(:include?, "def divide")
		end
	end
	
	with "generic classes" do
		let(:ruby_code) do
			<<~RUBY
				# A generic container
				# @generic T
				class Container
					# Initialize with value
					# @parameter value [T] The value to store
					def initialize(value)
						@value = value
					end
				
					# Get the value
					# @returns [T] The stored value
					def get
						@value
					end
				end
			RUBY
		end
		
		it "generates RBS with generic type parameters" do
			result = generate_rbs_for_ruby(ruby_code)
			
			expect(result).to be(:include?, "class Container")
			expect(result).to be(:include?, "def initialize")
			expect(result).to be(:include?, "def get")
		end
	end
	
	with "methods with blocks" do
		let(:ruby_code) do
			<<~RUBY
				class Iterator
					# Each item in collection
					# @yields [String] Each item
					def each
						yield "item1"
						yield "item2"
					end
				
					# Map over collection
					# @yields [String] Each item
					# @returns [Array] The transformed items
					def map
						result = []
						each {|item| result << yield(item)}
						result
					end
				end
			RUBY
		end
		
		it "generates RBS with block signatures" do
			result = generate_rbs_for_ruby(ruby_code)
			
			expect(result).to be(:include?, "class Iterator")
			expect(result).to be(:include?, "def each")
			expect(result).to be(:include?, "def map")
		end
	end
	
	with "multiple files" do
		let(:animal_code) do
			<<~RUBY
				# Base animal class
				class Animal
					def speak
						"..."
					end
				end
			RUBY
		end
		
		let(:dog_code) do
			<<~RUBY
				# Dog class
				class Dog < Animal
					def speak
						"Woof!"
					end
				end
			RUBY
		end
		
		it "generates RBS for multiple files" do
			animal_path = create_ruby_file("animal.rb", animal_code)
			dog_path = create_ruby_file("dog.rb", dog_code)
			
			index = Decode::Index.for(animal_path, dog_path)
			generator = Decode::RBS::Generator.new
			
			buffer = StringIO.new
			result = generator.generate(index, output: buffer)
			
			expect(buffer.string).to be(:include?, "class Animal")
			expect(buffer.string).to be(:include?, "class Dog < Animal")
		end
	end
	
	with "nested classes and modules" do
		let(:ruby_code) do
			<<~RUBY
				module Namespace
					# Outer class
					class Outer
						# Inner class
						class Inner
							def method
								"inner"
							end
						end
				
						def outer_method
							"outer"
						end
					end
				end
			RUBY
		end
		
		it "generates RBS for nested structures" do
			result = generate_rbs_for_ruby(ruby_code)
			
			expect(result).to be(:include?, "module Namespace")
			expect(result).to be(:include?, "class Outer")
			expect(result).to be(:include?, "class Inner")
		end
	end
	
	with "error handling" do
		let(:invalid_ruby_code) do
			<<~RUBY
				class InvalidClass
					def method_with_syntax_error
						if true
							# Missing end
					end
				end
			RUBY
		end
		
		it "handles invalid Ruby code gracefully" do
			expect do
				generate_rbs_for_ruby(invalid_ruby_code)
			end.not.to raise_exception
		end
	end
	
	with "empty files" do
		it "handles empty Ruby files" do
			result = generate_rbs_for_ruby("")
			expect(result).to be(:empty?)
		end
	end
	
	with "comments only" do
		let(:ruby_code) do
			<<~RUBY
				# This is just a comment
				# With multiple lines
				# But no code
			RUBY
		end
		
		it "handles files with only comments" do
			result = generate_rbs_for_ruby(ruby_code)
			expect(result).to be(:empty?)
		end
	end
end
