# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "decode/language/ruby"
require "decode/rbs/module"
require "decode/definition"
require "decode/documentation"
require "decode/comment/text"

describe Decode::RBS::Module do
	let(:language) {Decode::Language::Ruby.new}
	let(:comments) {[]}
	let(:definition) {Decode::Language::Ruby::Module.new([:TestModule], comments: comments, language: language)}
	let(:rbs_module) {subject.new(definition)}
	
	with "#initialize" do
		it "initializes with definition" do
			expect(rbs_module.instance_variable_get(:@definition)).to be == definition
		end
		
		it "inherits from Wrapper" do
			expect(rbs_module).to be_a(Decode::RBS::Wrapper)
		end
	end
	
	with "#to_rbs_ast" do
		with "basic module" do
			it "generates RBS AST for basic module" do
				ast = rbs_module.to_rbs_ast
				
				expect(ast).to be_a(::RBS::AST::Declarations::Module)
				expect(ast.name.name).to be == :TestModule
				expect(ast.name.namespace).to be == ::RBS::Namespace.empty
				expect(ast.type_params).to be(:empty?)
				expect(ast.self_types).to be(:empty?)
				expect(ast.members).to be(:empty?)
			end
		end
		
		with "module with methods" do
			let(:method_definition) {Decode::Language::Ruby::Method.new([:test_method])}
			
			it "includes method definitions in members" do
				ast = rbs_module.to_rbs_ast([method_definition])
				
				expect(ast.members).not.to be(:empty?)
				expect(ast.members.length).to be == 1
			end
		end
		
		with "module with documentation" do
			let(:comments) {["This is a test module"]}
			
			it "includes comment in RBS AST" do
				ast = rbs_module.to_rbs_ast
				
				expect(ast.comment).not.to be_nil
				expect(ast.comment.string).to be == "This is a test module"
			end
		end
	end
	
	with "private methods" do
		with "#simple_name_to_rbs" do
			it "converts simple name to RBS TypeName" do
				type_name = rbs_module.send(:simple_name_to_rbs, "TestModule")
				
				expect(type_name).to be_a(::RBS::TypeName)
				expect(type_name.name).to be == :TestModule
				expect(type_name.namespace).to be == ::RBS::Namespace.empty
			end
		end
		
		with "#comment" do
			with "definition with text documentation" do
				let(:comments) {["Test module comment"]}
				
				it "extracts comment from documentation" do
					comment = rbs_module.comment
					
					expect(comment).to be_a(::RBS::AST::Comment)
					expect(comment.string).to be == "Test module comment"
				end
			end
			
			with "definition without documentation" do
				it "returns nil when no documentation" do
					comment = rbs_module.comment
					expect(comment).to be_nil
				end
			end
			
			with "definition with multiple text lines" do
				let(:comments) {["First line", "Second line"]}
				
				it "joins multiple text lines with newlines" do
					comment = rbs_module.comment
					
					expect(comment).to be_a(::RBS::AST::Comment)
					expect(comment.string).to be == "First line\nSecond line"
				end
			end
		end
	end
end
