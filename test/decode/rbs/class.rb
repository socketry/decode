# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "decode/language/ruby"
require "decode/rbs/class"
require "decode/definition"
require "decode/documentation"
require "decode/comment/rbs"
require "decode/comment/text"

describe Decode::RBS::Class do
	let(:language) {Decode::Language::Ruby.new}
	let(:comments) {[]}
	let(:definition) {Decode::Language::Ruby::Class.new([:TestClass], comments: comments, language: language)}
	let(:rbs_class) {subject.new(definition)}
	
	with "#initialize" do
		it "initializes with definition and sets up instance variables" do
			expect(rbs_class.instance_variable_get(:@definition)).to be == definition
			expect(rbs_class.instance_variable_get(:@generics)).to be_nil
		end
		
		it "inherits from Wrapper" do
			expect(rbs_class).to be_a(Decode::RBS::Wrapper)
		end
	end
	
	with "#generics" do
		with "no RBS tags" do
			it "returns empty array when no generic tags found" do
				expect(rbs_class.generics).to be == []
			end
		end
		
		with "RBS tags with generic parameters" do
			let(:comments) {["@rbs generic T"]}
			
			it "extracts generic parameters from RBS tags" do
				expect(rbs_class.generics).to be == ["T"]
			end
		end
		
		with "multiple generic parameters" do
			let(:comments) {["@rbs generic T", "@rbs generic U"]}
			
			it "extracts multiple generic parameters" do
				expect(rbs_class.generics).to be == ["T", "U"]
			end
		end
	end
	
	with "#to_rbs_ast" do
		with "basic class" do
			it "generates RBS AST for basic class" do
				ast = rbs_class.to_rbs_ast
				
				expect(ast).to be_a(::RBS::AST::Declarations::Class)
				expect(ast.name.name).to be == :TestClass
				expect(ast.name.namespace).to be == ::RBS::Namespace.empty
				expect(ast.super_class).to be_nil
				expect(ast.type_params).to be(:empty?)
				expect(ast.members).to be(:empty?)
			end
		end
		
		with "class with super class" do
			let(:super_class) {"BaseClass"}
			let(:definition) {Decode::Language::Ruby::Class.new([:TestClass], comments: comments, super_class: super_class, language: language)}
			
			it "generates RBS AST with super class" do
				ast = rbs_class.to_rbs_ast
				
				expect(ast.super_class).not.to be_nil
				expect(ast.super_class.name.name).to be == :BaseClass
				expect(ast.super_class.name.namespace).not.to be(:absolute?)
			end
		end
		
		with "class with generic parameters" do
			let(:comments) {["@rbs generic T"]}
			
			it "generates RBS AST with type parameters" do
				ast = rbs_class.to_rbs_ast
				
				expect(ast.type_params).to have_attributes(length: be == 1)
				expect(ast.type_params.first.name).to be == :T
			end
		end
		
		with "class with methods" do
			let(:method_definition) {Decode::Language::Ruby::Method.new([:test_method])}
			
			it "includes method definitions in members" do
				ast = rbs_class.to_rbs_ast([method_definition])
				
				expect(ast.members).not.to be(:empty?)
				expect(ast.members.length).to be == 1
			end
		end
		
		with "class with documentation" do
			let(:comments) {["This is a test class"]}
			
			it "includes comment in RBS AST" do
				ast = rbs_class.to_rbs_ast
				
				expect(ast.comment).not.to be_nil
				expect(ast.comment.string).to be == "This is a test class"
			end
		end
	end
	
	with "private methods" do
		with "#simple_name_to_rbs" do
			it "converts simple name to RBS TypeName" do
				type_name = rbs_class.send(:simple_name_to_rbs, "TestClass")
				
				expect(type_name).to be_a(::RBS::TypeName)
				expect(type_name.name).to be == :TestClass
				expect(type_name.namespace).to be == ::RBS::Namespace.empty
			end
		end
		
		with "#qualified_name_to_rbs" do
			it "converts qualified name to RBS TypeName" do
				type_name = rbs_class.send(:qualified_name_to_rbs, "::Base::TestClass")
				
				expect(type_name).to be_a(::RBS::TypeName)
				expect(type_name.name).to be == :TestClass
				expect(type_name.namespace).not.to be(:absolute?)
				expect(type_name.namespace.path).to be == [:"", :Base]
			end
		end
		
		with "#comment" do
			with "definition with text documentation" do
				let(:comments) {["Test comment"]}
				
				it "extracts comment from documentation" do
					comment = rbs_class.comment
					
					expect(comment).to be_a(::RBS::AST::Comment)
					expect(comment.string).to be == "Test comment"
				end
			end
			
			with "definition without documentation" do
				it "returns nil when no documentation" do
					comment = rbs_class.comment
					expect(comment).to be_nil
				end
			end
		end
		
		with "#build_attributes_rbs (attribute type inference)" do
			with "attributes with type annotations" do
				let(:language) {Decode::Language::Ruby.new}
				let(:comments) {["@attribute [String] The name of the person."]}
				let(:attr_definition) {Decode::Language::Ruby::Attribute.new([:name], comments: comments, language: language)}
				let(:definition) {Decode::Language::Ruby::Class.new([:TestClass], language: language)}
				let(:rbs_class) {subject.new(definition)}
				
				it "generates attr_reader and instance variable declarations" do
					attributes, instance_variables = rbs_class.send(:build_attributes_rbs, [attr_definition])
					
					# Should generate one attr_reader
					expect(attributes).to have_attributes(length: be == 1)
					expect(attributes.first).to be_a(::RBS::AST::Members::AttrReader)
					expect(attributes.first.name).to be == :name
					expect(attributes.first.ivar_name).to be == :"@name"
					
					# Should generate one instance variable
					expect(instance_variables).to have_attributes(length: be == 1)
					expect(instance_variables.first).to be_a(::RBS::AST::Members::InstanceVariable)
					expect(instance_variables.first.name).to be == :"@name"
				end
				
				it "correctly parses String type" do
					attributes, _ = rbs_class.send(:build_attributes_rbs, [attr_definition])
					expect(attributes.first.type).to be_a(::RBS::Types::ClassInstance)
				end
			end
			
			with "complex type annotations" do
				let(:language) {Decode::Language::Ruby.new}
				let(:comments) {["@attribute [Hash(String, Source)] Mapping of paths to sources."]}
				let(:attr_definition) {Decode::Language::Ruby::Attribute.new([:sources], comments: comments, language: language)}
				let(:definition) {Decode::Language::Ruby::Class.new([:TestClass], language: language)}
				let(:rbs_class) {subject.new(definition)}
				
				it "correctly parses complex Hash types" do
					attributes, instance_variables = rbs_class.send(:build_attributes_rbs, [attr_definition])
					
					expect(attributes.first.name).to be == :sources
					expect(attributes.first.type).to be_a(::RBS::Types::ClassInstance)
				end
			end
			
			with "multiple attributes" do
				let(:language) {Decode::Language::Ruby.new}
				let(:name_attr) {Decode::Language::Ruby::Attribute.new([:name], comments: ["@attribute [String] The name."], language: language)}
				let(:count_attr) {Decode::Language::Ruby::Attribute.new([:count], comments: ["@attribute [Integer] The count."], language: language)}
				let(:definition) {Decode::Language::Ruby::Class.new([:TestClass], language: language)}
				let(:rbs_class) {subject.new(definition)}
				
				it "handles multiple attributes correctly" do
					attributes, instance_variables = rbs_class.send(:build_attributes_rbs, [name_attr, count_attr])
					
					expect(attributes).to have_attributes(length: be == 2)
					expect(instance_variables).to have_attributes(length: be == 2)
					
					# Check names
					names = attributes.map(&:name)
					expect(names.include?(:name)).to be == true
					expect(names.include?(:count)).to be == true
				end
			end
			
			with "attributes without type annotations" do
				let(:language) {Decode::Language::Ruby.new}
				let(:comments) {["This is just a regular comment without @attribute."]}
				let(:attr_definition) {Decode::Language::Ruby::Attribute.new([:name], comments: comments, language: language)}
				let(:definition) {Decode::Language::Ruby::Class.new([:TestClass], language: language)}
				let(:rbs_class) {subject.new(definition)}
				
				it "ignores attributes without @attribute annotations" do
					attributes, instance_variables = rbs_class.send(:build_attributes_rbs, [attr_definition])
					
					expect(attributes).to be(:empty?)
					expect(instance_variables).to be(:empty?)
				end
			end
			
			with "malformed type annotations" do
				let(:language) {Decode::Language::Ruby.new}
				let(:comments) {["@attribute [InvalidType(((] Malformed type."]}
				let(:attr_definition) {Decode::Language::Ruby::Attribute.new([:name], comments: comments, language: language)}
				let(:definition) {Decode::Language::Ruby::Class.new([:TestClass], language: language)}
				let(:rbs_class) {subject.new(definition)}
				
				it "gracefully handles malformed types by falling back to untyped" do
					attributes, instance_variables = rbs_class.send(:build_attributes_rbs, [attr_definition])
					
					expect(attributes).to have_attributes(length: be == 1)
					expect(attributes.first.type).to be_a(::RBS::Types::Bases::Any) # Should fallback to 'untyped'
				end
			end
		end
		
		with "#to_rbs_ast with attribute definitions" do
			let(:language) {Decode::Language::Ruby.new}
			let(:comments) {["@attribute [String] The name of the person."]}
			let(:attr_definition) {Decode::Language::Ruby::Attribute.new([:name], comments: comments, language: language)}
			let(:definition) {Decode::Language::Ruby::Class.new([:TestClass], language: language)}
			let(:rbs_class) {subject.new(definition)}
			
			it "includes attributes and instance variables in generated AST members" do
				ast = rbs_class.to_rbs_ast([], [], [attr_definition])
				
				# Should include both attr_reader and instance variable
				attr_readers = ast.members.select {|m| m.is_a?(::RBS::AST::Members::AttrReader)}
				instance_vars = ast.members.select {|m| m.is_a?(::RBS::AST::Members::InstanceVariable)}
				
				expect(attr_readers).to have_attributes(length: be == 1)
				expect(instance_vars).to have_attributes(length: be == 1)
				expect(attr_readers.first.name).to be == :name
				expect(instance_vars.first.name).to be == :"@name"
			end
		end
		
		with "#build_constant_rbs (constant type inference)" do
			with "constants with type annotations" do
				let(:language) {Decode::Language::Ruby.new}
				let(:comments) {["@constant [String] The default configuration file name."]}
				let(:const_definition) {Decode::Language::Ruby::Constant.new([:CONFIG_FILE], comments: comments, language: language)}
				let(:definition) {Decode::Language::Ruby::Class.new([:TestClass], language: language)}
				let(:rbs_class) {subject.new(definition)}
				
				it "generates constant RBS declaration" do
					constant_rbs = rbs_class.send(:build_constant_rbs, const_definition)
					
					expect(constant_rbs).to be_a(::RBS::AST::Declarations::Constant)
					expect(constant_rbs.name).to be == :CONFIG_FILE
					expect(constant_rbs.type).to be_a(::RBS::Types::ClassInstance)
				end
				
				it "correctly parses String type" do
					constant_rbs = rbs_class.send(:build_constant_rbs, const_definition)
					expect(constant_rbs.type).to be_a(::RBS::Types::ClassInstance)
				end
			end
			
			with "complex constant types" do
				let(:language) {Decode::Language::Ruby.new}
				let(:comments) {["@constant [Hash(Symbol, String)] Default configuration values."]}
				let(:const_definition) {Decode::Language::Ruby::Constant.new([:DEFAULT_CONFIG], comments: comments, language: language)}
				let(:definition) {Decode::Language::Ruby::Class.new([:TestClass], language: language)}
				let(:rbs_class) {subject.new(definition)}
				
				it "correctly parses complex Hash types" do
					constant_rbs = rbs_class.send(:build_constant_rbs, const_definition)
					
					expect(constant_rbs.name).to be == :DEFAULT_CONFIG
					expect(constant_rbs.type).to be_a(::RBS::Types::ClassInstance)
				end
			end
			
			with "constants without type annotations" do
				let(:language) {Decode::Language::Ruby.new}
				let(:comments) {["This is just a regular comment without @constant."]}
				let(:const_definition) {Decode::Language::Ruby::Constant.new([:SOME_CONSTANT], comments: comments, language: language)}
				let(:definition) {Decode::Language::Ruby::Class.new([:TestClass], language: language)}
				let(:rbs_class) {subject.new(definition)}
				
				it "ignores constants without @constant annotations" do
					constant_rbs = rbs_class.send(:build_constant_rbs, const_definition)
					expect(constant_rbs).to be_nil
				end
			end
			
			with "malformed constant type annotations" do
				let(:language) {Decode::Language::Ruby.new}
				let(:comments) {["@constant [InvalidType(((] Malformed type."]}
				let(:const_definition) {Decode::Language::Ruby::Constant.new([:BAD_CONSTANT], comments: comments, language: language)}
				let(:definition) {Decode::Language::Ruby::Class.new([:TestClass], language: language)}
				let(:rbs_class) {subject.new(definition)}
				
				it "gracefully handles malformed types by falling back to untyped" do
					constant_rbs = rbs_class.send(:build_constant_rbs, const_definition)
					
					expect(constant_rbs).not.to be_nil
					expect(constant_rbs.name).to be == :BAD_CONSTANT
					expect(constant_rbs.type).to be_a(::RBS::Types::Bases::Any) # Should fallback to 'untyped'
				end
			end
			
			with "Array and Union types" do
				let(:language) {Decode::Language::Ruby.new}
				let(:comments) {["@constant [Array(String)] List of supported formats."]}
				let(:const_definition) {Decode::Language::Ruby::Constant.new([:SUPPORTED_FORMATS], comments: comments, language: language)}
				let(:definition) {Decode::Language::Ruby::Class.new([:TestClass], language: language)}
				let(:rbs_class) {subject.new(definition)}
				
				it "correctly parses Array types" do
					constant_rbs = rbs_class.send(:build_constant_rbs, const_definition)
					
					expect(constant_rbs.name).to be == :SUPPORTED_FORMATS
					expect(constant_rbs.type).to be_a(::RBS::Types::ClassInstance)
				end
			end
		end
		
		with "#to_rbs_ast with constant definitions" do
			let(:language) {Decode::Language::Ruby.new}
			let(:comments) {["@constant [String] The version string."]}
			let(:const_definition) {Decode::Language::Ruby::Constant.new([:VERSION], comments: comments, language: language)}
			let(:definition) {Decode::Language::Ruby::Class.new([:TestClass], language: language)}
			let(:rbs_class) {subject.new(definition)}
			
			it "includes constants in generated AST members" do
				ast = rbs_class.to_rbs_ast([], [const_definition], [])
				
				# Should include constants in members
				constants = ast.members.select {|m| m.is_a?(::RBS::AST::Declarations::Constant)}
				
				expect(constants).to have_attributes(length: be == 1)
				expect(constants.first.name).to be == :VERSION
				expect(constants.first.type).to be_a(::RBS::Types::ClassInstance)
			end
		end
	end
end
