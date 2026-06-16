# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require "decode/source"
require "decode/language/ruby"

describe Decode::Language::Ruby do
	let(:path) {File.expand_path(".fixtures/ruby.rb", __dir__)}
	let(:language) {subject.new}
	let(:source) {Decode::Source.new(path, language)}
	let(:definitions) {source.definitions.to_a}
	let(:segments) {source.segments.to_a}
	
	with "classes" do
		let(:path) {File.expand_path(".fixtures/classes.rb", __dir__)}
		
		it "can extract definitions" do
			expect(definitions).not.to be(:empty?)
		end
		
		it "has a location" do
			location = definitions.first.location
			expect(location).not.to be_nil
			expect(location.path).to be == path
			expect(location.line).to be == 6
			expect(location.to_s).to be == "#{path}:6"
		end
		
		it "has short form" do
			expect(definitions[0].short_form).to be == "class Parent"
			expect(definitions[1].short_form).to be == "class Child"
			expect(definitions[2].short_form).to be == "class << self"
			expect(definitions[3].short_form).to be == "class Child"
		end
		
		it "has long form" do
			expect(definitions[0].long_form).to be == "class Parent"
			expect(definitions[1].long_form).to be == "class Child < Parent"
			expect(definitions[2].long_form).to be == "class << self"
			expect(definitions[3].long_form).to be == "class My::Nested::Child"
		end
		
		it "should handle singleton classes" do
			singleton_classes = definitions.select do |definition|
				definition.is_a?(Decode::Language::Ruby::Singleton)
			end
			expect(singleton_classes.size).to be > 0
		end
	end
	
	with "modules" do
		let(:path) {File.expand_path(".fixtures/modules.rb", __dir__)}
		
		it "can extract definitions" do
			expect(definitions).not.to be(:empty?)
		end
		
		it "has short form" do
			expect(definitions[0].short_form).to be == "module X"
			expect(definitions[1].short_form).to be == "module Y"
		end
		
		it "has long form" do
			expect(definitions[0].long_form).to be == "module X"
			expect(definitions[1].long_form).to be == "module X::Y"
		end
		
		it "has fully qualified form" do
			expect(definitions[0].qualified_form).to be == "module X"
			expect(definitions[1].qualified_form).to be == "module X::Y"
		end
	end
	
	with "nested modules" do
		let(:path) {File.expand_path(".fixtures/nested_modules.rb", __dir__)}
		
		it "can extract definitions" do
			expect(definitions).not.to be(:empty?)
		end
		
		it "has short form" do
			expect(definitions[0].short_form).to be == "module Y"
			expect(definitions[1].short_form).to be == "module Z"
		end
		
		it "has full path" do
			expect(definitions[1].full_path).to be == [:X, :Y, :Z]
		end
		
		it "has long form" do
			expect(definitions[0].long_form).to be == "module X::Y"
			expect(definitions[1].long_form).to be == "module X::Y::Z"
		end
		
		it "has fully qualified form" do
			expect(definitions[0].qualified_form).to be == "module X::Y"
			expect(definitions[1].qualified_form).to be == "module X::Y::Z"
		end
		
		it "should handle complex constant paths" do
			# Should have modules with nested paths
			modules = definitions.select do |definition|
				definition.is_a?(Decode::Language::Ruby::Module)
			end
			expect(modules.size).to be > 0
		end
	end
	
	with "instance methods" do
		let(:path) {File.expand_path(".fixtures/instance_methods.rb", __dir__)}
		
		it "can extract definitions" do
			expect(definitions).not.to be(:empty?)
		end
		
		it "has short form" do
			expect(definitions[0].short_form).to be == "def without_arguments"
			expect(definitions[1].short_form).to be == "def with_arguments"
		end
		
		it "has long form" do
			expect(definitions[0].long_form).to be == "def without_arguments"
			expect(definitions[1].long_form).to be == "def with_arguments(x = 10)"
		end
	end
	
	with "class methods" do
		let(:path) {File.expand_path(".fixtures/class_methods.rb", __dir__)}
		
		it "can extract definitions" do
			expect(definitions).not.to be(:empty?)
		end
		
		it "has short form" do
			expect(definitions[0].short_form).to be == "def self.without_arguments"
			expect(definitions[1].short_form).to be == "def self.with_arguments"
		end
		
		it "has long form" do
			expect(definitions[0].long_form).to be == "def self.without_arguments"
			expect(definitions[1].long_form).to be == "def self.with_arguments(x = 10)"
		end
		
		it "should handle method definitions with complex receivers" do
			methods = definitions.select do |definition|
				definition.is_a?(Decode::Language::Ruby::Method)
			end
			
			# Should have methods with self receivers
			class_methods = methods.select do |method|
				method.receiver == "self"
			end
			expect(class_methods.size).to be > 0
		end
	end
	
	with "functions" do
		let(:path) {File.expand_path(".fixtures/functions.rb", __dir__)}
		
		it "can extract definitions" do
			expect(definitions).not.to be(:empty?)
		end
		
		it "has short form" do
			expect(definitions[1].short_form).to be == "def Foo.bar"
		end
		
		it "has long form" do
			expect(definitions[1].long_form).to be == "def Foo.bar(...)"
		end
		
		it "has correct path" do
			expect(definitions[1].full_path).to be == [:Foo, :bar]
		end
	end
	
	with "constants" do
		let(:path) {File.expand_path(".fixtures/constants.rb", __dir__)}
		
		it "can extract definitions" do
			expect(definitions).not.to be(:empty?)
		end
		
		it "has short form" do
			expect(definitions[0].short_form).to be == "SINGLE_LINE_STRING"
			expect(definitions[1].short_form).to be == "MULTI_LINE_ARRAY"
			expect(definitions[2].short_form).to be == "MULTI_LINE_HASH"
		end
		
		it "has long form" do
			expect(definitions[0].long_form).to be == 'SINGLE_LINE_STRING = "Hello World"'
			expect(definitions[1].long_form).to be == "MULTI_LINE_ARRAY = [...]"
			expect(definitions[2].long_form).to be == "MULTI_LINE_HASH = {...}"
		end
	end
	
	with "attributes" do
		let(:path) {File.expand_path(".fixtures/attributes.rb", __dir__)}
		
		it "can extract definitions" do
			expect(definitions).not.to be(:empty?)
		end
		
		it "has short form" do
			expect(definitions[0].short_form).to be == "attr :a"
			expect(definitions[1].short_form).to be == "attr_reader :b"
			expect(definitions[2].short_form).to be == "attr_writer :c"
			expect(definitions[3].short_form).to be == "attr_accessor :d"
		end
		
		it "has long form" do
			expect(definitions[0].long_form).to be == "attr :a"
			expect(definitions[1].long_form).to be == "attr_reader :b"
			expect(definitions[2].long_form).to be == "attr_writer :c"
			expect(definitions[3].long_form).to be == "attr_accessor :d"
		end
		
		it "should handle complex attribute definitions" do
			attributes = definitions.select do |definition|
				definition.is_a?(Decode::Language::Ruby::Attribute)
			end
			
			expect(attributes.size).to be > 0
		end
	end
	
	with "comments" do
		let(:path) {File.expand_path(".fixtures/comments.rb", __dir__)}
		
		it "can extract definitions" do
			expect(definitions).not.to be(:empty?)
		end
		
		it "can extract segments" do
			expect(segments).not.to be(:empty?)
			expect(segments.size).to be == 2
		end
		
		it "can extract comments" do
			expect(segments[0].comments).to be == ["Firstly, we define a method:"]
			expect(segments[1].comments).to be == ["Then we invoke it:"]
		end
		
		it "can extract code" do
			expect(segments[0].code).to be == "def method\n\t# Frobulate the combobulator:\n\t$combobulator.frobulate\nend"
			expect(segments[1].code).to be == "result = self.method\nputs result"
		end
	end
	
	with "block" do
		let(:path) {File.expand_path(".fixtures/block.rb", __dir__)}
		
		it "can extract definitions" do
			expect(definitions).not.to be(:empty?)
		end
		
		it "defines scope" do
			expect(definitions[0].name).to be == :Foo
			expect(definitions[1].name).to be == :Bar
		end
		
		it "has short form" do
			expect(definitions[2].short_form).to be == "local"
			expect(definitions[3].short_form).to be == "hostname"
			expect(definitions[4].short_form).to be == "context { ... }"
		end
		
		it "has long form" do
			expect(definitions[2].long_form).to be == "add(:local)"
			expect(definitions[3].long_form).to be == "hostname \"localhost\""
			expect(definitions[4].long_form).to be == "context {Context.new(hostname)}"
		end
		
		it "has text" do
			expect(definitions[2].text).to be == <<~TEXT.chomp
			add(:local) do
				# The default hostname for the connection.
				# @name hostname
				# @attribute [String]
				hostname "localhost"
				
				# The default context for managing the connection.
				# @attribute [Context]
				context {Context.new(hostname)}
			end
			TEXT
		end
		
		it "has correct nesting" do
			expect(definitions[2]).to be(:container?)
			expect(definitions[4]).not.to be(:container?)
		end
	end
	
	with "private" do
		let(:path) {File.expand_path(".fixtures/private.rb", __dir__)}
		
		it "can extract definitions" do
			expect(definitions).not.to be(:empty?)
		end
		
		it "has public and private methods" do
			expect(definitions.size).to be == 7
			expect(definitions[0].visibility).to be == :public
			expect(definitions[1].visibility).to be == :public
			expect(definitions[2].visibility).to be == :public
			expect(definitions[3].visibility).to be == :private
			expect(definitions[4].visibility).to be == :private
			expect(definitions[5].visibility).to be == :public
			expect(definitions[6].visibility).to be == :public
		end
	end
	
	with "inline visibility" do
		let(:path) {File.expand_path(".fixtures/inline_visibility.rb", __dir__)}
		
		it "can extract definitions" do
			expect(definitions).not.to be(:empty?)
		end
		
		it "handles inline visibility modifiers correctly" do
			expect(definitions.size).to be == 11
			
			# First definition is the class itself
			expect(definitions[0].name).to be == :VisibilityTest
			expect(definitions[0].visibility).to be == :public
			
			# Test that inline visibility modifiers only affect the specific method
			expect(definitions[1].name).to be == :public_method_1
			expect(definitions[1].visibility).to be == :public
			
			expect(definitions[2].name).to be == :private_method_1
			expect(definitions[2].visibility).to be == :private
			
			expect(definitions[3].name).to be == :public_method_2
			expect(definitions[3].visibility).to be == :public  # Should remain public after inline private
			
			expect(definitions[4].name).to be == :protected_method_1
			expect(definitions[4].visibility).to be == :protected
			
			expect(definitions[5].name).to be == :public_method_3
			expect(definitions[5].visibility).to be == :public  # Should remain public after inline protected
			
			expect(definitions[6].name).to be == :public_method_4
			expect(definitions[6].visibility).to be == :public
			
			# Test that standalone modifiers still work after inline modifiers
			expect(definitions[7].name).to be == :private_method_2
			expect(definitions[7].visibility).to be == :private
			
			expect(definitions[8].name).to be == :private_method_3
			expect(definitions[8].visibility).to be == :private
			
			expect(definitions[9].name).to be == :protected_method_2
			expect(definitions[9].visibility).to be == :protected
			
			expect(definitions[10].name).to be == :public_method_5
			expect(definitions[10].visibility).to be == :public
		end
	end
	
	with "enumerator functionality" do
		let(:path) {File.expand_path(".fixtures/classes.rb", __dir__)}
		
		it "should return an enumerator when no block is given" do
			enumerator = language.definitions_for(source)
			expect(enumerator).to be_a(Enumerator)
		end
		
		it "should yield definitions when enumerator is used" do
			definitions = language.definitions_for(source).to_a
			expect(definitions.size).to be > 0
			
			definitions.each do |definition|
				expect(definition).to be_a(Decode::Definition)
			end
		end
		
		it "should work with enumerator methods" do
			definitions = language.definitions_for(source)
			
			# Test select
			classes = definitions.select do |definition|
				definition.is_a?(Decode::Language::Ruby::Class)
			end
			expect(classes.size).to be > 0
			
			# Test map
			names = definitions.map(&:name)
			expect(names.size).to be > 0
			
			# Test count
			count = definitions.count
			expect(count).to be > 0
		end
		
		it "should provide the same results when called multiple times" do
			definitions1 = language.definitions_for(source).to_a
			definitions2 = language.definitions_for(source).to_a
			
			expect(definitions1.size).to be == definitions2.size
			expect(definitions1.map(&:name)).to be == definitions2.map(&:name)
		end
	end
	
	with "helper methods" do
		let(:parser) {language.parser}
		
		with "#symbol_name_for" do
			it "should extract symbol names" do
				code = "alias_method :new_name, :old_name"
				result = Prism.parse(code)
				node = result.value.statements.body.first
				new_name_arg = node.arguments.arguments[0]
				old_name_arg = node.arguments.arguments[1]
				
				expect(parser.send(:symbol_name_for, new_name_arg)).to be == "new_name"
				expect(parser.send(:symbol_name_for, old_name_arg)).to be == "old_name"
			end
			
			it "should extract string names" do
				code = 'alias_method "new_name", "old_name"'
				result = Prism.parse(code)
				node = result.value.statements.body.first
				new_name_arg = node.arguments.arguments[0]
				old_name_arg = node.arguments.arguments[1]
				
				expect(parser.send(:symbol_name_for, new_name_arg)).to be == '"new_name"'
				expect(parser.send(:symbol_name_for, old_name_arg)).to be == '"old_name"'
			end
		end
		
		with "#receiver_for" do
			it "should handle self receiver" do
				code = "def self.foo; end"
				result = Prism.parse(code)
				node = result.value.statements.body.first
				
				expect(parser.send(:receiver_for, node.receiver)).to be == "self"
			end
			
			it "should handle constant receiver" do
				code = "def Test.foo; end"
				result = Prism.parse(code)
				node = result.value.statements.body.first
				
				expect(parser.send(:receiver_for, node.receiver)).to be == "Test"
			end
			
			it "should handle constant path receiver" do
				code = "def Nested::Class.foo; end"
				result = Prism.parse(code)
				node = result.value.statements.body.first
				
				expect(parser.send(:receiver_for, node.receiver)).to be == "Nested"
			end
			
			it "should handle nil receiver" do
				code = "def foo; end"
				result = Prism.parse(code)
				node = result.value.statements.body.first
				
				expect(parser.send(:receiver_for, node.receiver)).to be == nil
			end
		end
		
		with "#nested_name_for" do
			it "should handle simple constant" do
				code = "class Test; end"
				result = Prism.parse(code)
				node = result.value.statements.body.first
				
				expect(parser.send(:nested_name_for, node.constant_path)).to be == "Test"
			end
			
			it "should handle nested constant" do
				code = "class Nested::Test; end"
				result = Prism.parse(code)
				node = result.value.statements.body.first
				
				expect(parser.send(:nested_name_for, node.constant_path)).to be == "Nested::Test"
			end
			
			it "should handle nil" do
				expect(parser.send(:nested_name_for, nil)).to be == nil
			end
		end
		
		with "#singleton_name_for" do
			it "should handle self singleton" do
				code = "class << self; end"
				result = Prism.parse(code)
				node = result.value.statements.body.first
				
				expect(parser.send(:singleton_name_for, node)).to be == "self"
			end
			
			it "should handle constant singleton" do
				code = "class << Test; end"
				result = Prism.parse(code)
				node = result.value.statements.body.first
				
				expect(parser.send(:singleton_name_for, node)).to be == "Test"
			end
		end
	end
	
	with "edge cases" do
		let(:parser) {language.parser}
		
		it "should handle inline visibility with non-method definitions" do
			code = "private :some_method"
			
			definitions = parser.definitions_for(code).to_a
			
			# This should not create any definitions but should set visibility state
			expect(definitions.size).to be == 0
		end
		
		it "should handle attribute with call node argument" do
			code = "
			# @name custom_name
			attr_reader some_method_call()
			"
			
			definitions = parser.definitions_for(code).to_a
			
			expect(definitions.size).to be == 1
			expect(definitions.first.name).to be == :custom_name
		end
		
		it "should handle attribute with block node argument" do
			code = "
			# @name block_attr
			attr_reader { block_content }
			"
			
			definitions = parser.definitions_for(code).to_a
			
			expect(definitions.size).to be == 1
			expect(definitions.first.name).to be == :block_attr
		end
	end
	
	with "indented methods" do
		let(:path) {File.expand_path(".fixtures/indented_methods.rb", __dir__)}
		
		it "can extract definitions" do
			expect(definitions).not.to be(:empty?)
		end
		
		it "has text with normalized indentation" do
			# Find the simple_method definition
			simple_method = definitions.find{|definition| definition.name == :simple_method}
			expect(simple_method).not.to be_nil
			
			# The text should have normalized indentation (no leading tabs)
			expect(simple_method.text).to be == <<~TEXT.chomp
				def simple_method
					"Hello World"
				end
			TEXT
		end
		
		it "has text with normalized indentation for complex methods" do
			# Find the complex_method definition
			complex_method = definitions.find{|definition| definition.name == :complex_method}
			expect(complex_method).not.to be_nil
			
			# The text should have normalized indentation (no leading tabs)
			expect(complex_method.text).to be == <<~TEXT.chomp
				def complex_method(name)
					greeting = "Hello"
					message = "\#{greeting}, \#{name}!"
					
					# Add some extra processing
					if name.length > 5
						message += " You have a long name!"
					end
					
					return message
				end
			TEXT
		end
		
		it "has text with normalized indentation for methods with blocks" do
			# Find the method_with_block definition
			block_method = definitions.find{|definition| definition.name == :method_with_block}
			expect(block_method).not.to be_nil
			
			# The text should have normalized indentation (no leading tabs)
			expect(block_method.text).to be == <<~TEXT.chomp
				def method_with_block
					lines = [
						"First line",
						"Second line",
						"Third line"
					]
					
					lines.each do |line|
						yield line
					end
				end
			TEXT
		end
	end
	
	with "singleton class" do
		let(:path) {File.expand_path(".fixtures/singleton_class.rb", __dir__)}
		
		it "can extract singleton class definitions" do
			# Should find both the class and the singleton class
			class_definition = definitions.find{|definition| definition.name == :Foo}
			singleton_definition = definitions.find{|definition| definition.short_form == "class << self"}
			
			expect(singleton_definition).to have_attributes(
				qualified_name: be == "Foo::class",
			)
			
			expect(class_definition).not.to be_nil
			expect(singleton_definition).not.to be_nil
		end
		
		it "has correct text for singleton class" do
			singleton_definition = definitions.find{|definition| definition.short_form == "class << self"}
			expect(singleton_definition).not.to be_nil
			expect(singleton_definition.text).to be == <<~RUBY.chomp
				class << self
					# Singleton method
					def bar
					end
				end
			RUBY
		end
	end
	
	with "if/else/elsif methods" do
		let(:path) {File.expand_path(".fixtures/if_else_methods.rb", __dir__)}
		
		it "extracts methods from all branches of if/else/elsif" do
			method_names = definitions.map(&:name)
			expect(method_names).to be(:include?, :method_in_if)
			expect(method_names).to be(:include?, :method_in_else)
			expect(method_names).to be(:include?, :method_in_if_false)
			expect(method_names).to be(:include?, :method_in_elsif)
			expect(method_names).to be(:include?, :method_in_final_else)
		end
	end
	
	with "unless/else methods" do
		let(:path) {File.expand_path(".fixtures/unless_else_methods.rb", __dir__)}
		
		it "extracts methods from all branches of unless/else" do
			method_names = definitions.map(&:name)
			expect(method_names).to be(:include?, :foo)
			expect(method_names).to be(:include?, :bar)
			expect(method_names).to be(:include?, :baz)
		end
	end
	
	with "call node with block argument" do
		let(:path) {File.expand_path(".fixtures/block_argument.rb", __dir__)}
		
		it "does not raise when block argument is not a block_node" do
			definitions.each do |definition|
				expect{definition.container?}.not.to raise_exception
			end
		end
	end
end
