# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "decode/language/ruby"
require "decode/rbs/method"
require "decode/definition"
require "decode/documentation"
require "decode/comment/rbs"
require "decode/comment/text"
require "decode/comment/returns"
require "decode/comment/parameter"
require "decode/comment/option"
require "decode/comment/yields"
require "decode/source"
require "decode/index"

describe Decode::RBS::Method do
	let(:language) {Decode::Language::Ruby.new}
	let(:comments) {[]}
	let(:definition) {Decode::Language::Ruby::Method.new([:test_method], comments: comments, language: language)}
	let(:rbs_method) {subject.new(definition)}
	
	with "#initialize" do
		it "initializes with definition and sets up instance variables" do
			expect(rbs_method.instance_variable_get(:@definition)).to be == definition
			expect(rbs_method.instance_variable_get(:@signatures)).to be_nil
		end
		
		it "inherits from Wrapper" do
			expect(rbs_method).to be_a(Decode::RBS::Wrapper)
		end
	end
	
	with "#signatures" do
		with "no RBS tags" do
			it "returns empty array when no method signature tags found" do
				expect(rbs_method.signatures).to be == []
			end
		end
		
		with "RBS tags with method signatures" do
			let(:comments) {["@rbs (String) -> Integer"]}
			
			it "extracts method signatures from RBS tags" do
				expect(rbs_method.signatures).to be == ["(String) -> Integer"]
			end
		end
		
		with "multiple method signatures" do
			let(:comments) {["@rbs (String) -> Integer", "@rbs (Integer) -> String"]}
			
			it "extracts multiple method signatures" do
				expect(rbs_method.signatures).to be == ["(String) -> Integer", "(Integer) -> String"]
			end
		end
	end
	
	with "#to_rbs_ast" do
		with "method with explicit signatures" do
			let(:comments) {["@rbs (String) -> Integer"]}
			
			it "generates RBS AST with explicit signatures" do
				ast = rbs_method.to_rbs_ast
				
				expect(ast).to be_a(::RBS::AST::Members::MethodDefinition)
				expect(ast.name).to be == :test_method
				expect(ast.overloads).to have_attributes(length: be == 1)
			end
		end
		
		with "method without explicit signatures" do
			it "generates RBS AST with inferred types" do
				ast = rbs_method.to_rbs_ast
				
				expect(ast).to be_a(::RBS::AST::Members::MethodDefinition)
				expect(ast.name).to be == :test_method
				expect(ast.overloads).to have_attributes(length: be == 1)
			end
		end
		
		with "method with documentation" do
			let(:comments) {["This is a test method"]}
			
			it "includes comment in RBS AST" do
				ast = rbs_method.to_rbs_ast
				
				expect(ast.comment).not.to be_nil
				expect(ast.comment.string).to be == "This is a test method"
			end
		end
		
		with "method with @option parameters and union return type" do
			let(:comments) {[
				"A method with options and multiple return types",
				"@parameter name [String] The name parameter", 
				"@option :format [Symbol] Required output format",
				"@option :cached [Boolean?] Optional caching",
				"@option :timeout [Integer?] Optional timeout",
				"@returns [String]",
				"@returns [nil]"
			]}
			
			it "generates RBS AST with keyword arguments and union return type" do
				ast = rbs_method.to_rbs_ast
				
				expect(ast).to be_a(::RBS::AST::Members::MethodDefinition)
				expect(ast.name).to be == :test_method
				expect(ast.overloads).to have_attributes(length: be == 1)
				
				overload = ast.overloads.first
				function_type = overload.method_type.type
				
				# Check positional parameters
				expect(function_type.required_positionals).to have_attributes(length: be == 1)
				expect(function_type.required_positionals.first.name).to be == :name
				
				# Check required keyword arguments (non-nullable types)
				expect(function_type.required_keywords).to have_attributes(length: be == 1)
				expect(function_type.required_keywords.keys).to be == [:format]
				
				# Check optional keyword arguments (nullable types)
				expect(function_type.optional_keywords).to have_attributes(length: be == 2)
				expect(function_type.optional_keywords.keys).to be == [:cached, :timeout]
				
				# Check union return type
				expect(function_type.return_type).to be_a(::RBS::Types::Union)
				expect(function_type.return_type.types).to have_attributes(length: be == 2)
			end
		end
	end
	
	with "private methods" do
		
		
		with "#return_type" do
			with "method with @returns tag" do
				let(:comments) {["@returns [String]"]}
				
				it "extracts return type from @returns tag" do
					return_type = rbs_method.return_type
					expect(return_type).not.to be_nil
					# The exact type depends on the RBS::Parser.parse_type implementation
				end
			end
			
			with "method with multiple @returns tags" do
				let(:comments) {["@returns [String]", "@returns [Integer]"]}
				
				it "creates union type for multiple return types" do
					return_type = rbs_method.return_type
					expect(return_type).to be_a(::RBS::Types::Union)
					expect(return_type.types).to have_attributes(length: be == 2)
				end
			end
			
			with "method with multiple @returns tags of different types" do
				let(:comments) {["@returns [String]", "@returns [Integer]", "@returns [nil]"]}
				
				it "creates union type with all specified types" do
					return_type = rbs_method.return_type
					expect(return_type).to be_a(::RBS::Types::Union)
					expect(return_type.types).to have_attributes(length: be == 3)
				end
			end
			
			with "method without @returns tag" do
				it "falls back to inferred return type" do
					return_type = rbs_method.return_type
					expect(return_type.to_s).to be == "untyped"
				end
			end
		end
		
		with "#parameters" do
			with "method with @parameter tags" do
				let(:comments) {["@parameter name [String] The name parameter"]}
				
				it "extracts parameters from @parameter tags" do
					parameters = rbs_method.parameters
					expect(parameters).to have_attributes(length: be == 1)
					expect(parameters.first.name).to be == :name
				end
			end
			
			with "method with @parameter and @option tags" do
				let(:comments) {["@parameter name [String] The name parameter", "@option :cached [bool] Whether to cache"]}
				
				it "only extracts @parameter tags, not @option tags" do
					parameters = rbs_method.parameters
					expect(parameters).to have_attributes(length: be == 1)
					expect(parameters.first.name).to be == :name
				end
			end
			
			with "method without @parameter tags" do
				it "returns empty array when no parameter tags" do
					parameters = rbs_method.parameters
					expect(parameters).to be == []
				end
			end
		end
		
		with "#keyword_arguments" do
			with "method with required @option tags" do
				let(:comments) {["@option :format [Symbol] The output format", "@option :mode [String] Processing mode"]}
				
				it "extracts required keyword arguments from non-nullable @option tags" do
					keywords = rbs_method.keyword_arguments
					expect(keywords[:required]).to have_attributes(length: be == 2)
					expect(keywords[:required].keys).to be == [:format, :mode]
					expect(keywords[:optional]).to have_attributes(length: be == 0)
				end
			end
			
			with "method with optional @option tags" do
				let(:comments) {["@option :cached [Boolean?] Whether to cache the result", "@option :timeout [Integer?] Request timeout"]}
				
				it "extracts optional keyword arguments from nullable @option tags" do
					keywords = rbs_method.keyword_arguments
					expect(keywords[:optional]).to have_attributes(length: be == 2)
					expect(keywords[:optional].keys).to be == [:cached, :timeout]
					expect(keywords[:required]).to have_attributes(length: be == 0)
				end
			end
			
			with "method with mixed required and optional @option tags" do
				let(:comments) {["@option :format [Symbol] Required format", "@option :validate [Boolean?] Optional validation"]}
				
				it "correctly separates required and optional keyword arguments" do
					keywords = rbs_method.keyword_arguments
					expect(keywords[:required]).to have_attributes(length: be == 1)
					expect(keywords[:required].keys).to be == [:format]
					expect(keywords[:optional]).to have_attributes(length: be == 1)
					expect(keywords[:optional].keys).to be == [:validate]
				end
			end
			
			with "method with @option tags without leading colon" do
				let(:comments) {["@option cached [Boolean?] Whether to cache the result"]}
				
				it "handles option names without leading colon" do
					keywords = rbs_method.keyword_arguments
					expect(keywords[:optional]).to have_attributes(length: be == 1)
					expect(keywords[:optional].keys).to be == [:cached]
				end
			end
			
			with "method without @option tags" do
				it "returns empty keyword hashes when no option tags" do
					keywords = rbs_method.keyword_arguments
					expect(keywords[:optional]).to have_attributes(length: be == 0)
					expect(keywords[:required]).to have_attributes(length: be == 0)
				end
			end
			
		end
		
		
		
		with "#extract_block_type" do
			with "method with @yields tag" do
				let(:comments) {["@yields {|item| ...} Each item in the collection"]}
				
				it "extracts block type from @yields tag" do
					block_type = rbs_method.send(:extract_block_type, definition, nil)
					expect(block_type).to be_a(::RBS::Types::Block)
					expect(block_type.required).to be_truthy
				end
			end
			
			with "method without @yields tag" do
				it "returns nil when no yields tag" do
					block_type = rbs_method.send(:extract_block_type, definition, nil)
					expect(block_type).to be_nil
				end
			end
		end
		
		
		with "#comment" do
			with "method with text documentation" do
				let(:comments) {["Test method comment"]}
				
				it "extracts comment from documentation" do
					comment = rbs_method.comment
					
					expect(comment).to be_a(::RBS::AST::Comment)
					expect(comment.string).to be == "Test method comment"
				end
			end
			
			with "method without documentation" do
				it "returns nil when no documentation" do
					comment = rbs_method.comment
					expect(comment).to be_nil
				end
			end
		end
	end
	
	with "parameter forwarding" do
		let(:fixture_path) { File.expand_path(".fixtures/parameter_forwarding.rb", __dir__) }
		let(:source) { Decode::Source.new(fixture_path, Decode::Language::Ruby.new) }
		let(:definitions) { source.definitions.to_a }
		let(:method_def) { definitions.find { |d| d.name == :forward } }
		let(:method_wrapper) { Decode::RBS::Method.new(method_def) }
		
		it "handles parameter forwarding syntax without error" do
			# This should not raise NoMethodError for ForwardingParameterNode
			expect { method_wrapper.to_rbs_ast(nil) }.not.to raise_exception
		end
		
		it "generates valid RBS for forwarding parameters" do
			rbs_ast = method_wrapper.to_rbs_ast(nil)
			expect(rbs_ast).to be_a(::RBS::AST::Members::MethodDefinition)
			expect(rbs_ast.name).to be == :forward
		end
	end
end
