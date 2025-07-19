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
	end
end
