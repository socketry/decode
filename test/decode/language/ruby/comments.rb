# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "decode/language/ruby"
require "decode/source"
require "decode/documentation"

describe Decode::Language::Ruby do
	let(:language) {Decode::Language::Ruby.new}
	let(:source) {Decode::Source.new(path, language)}
	let(:definitions) {language.definitions_for(source).to_a}
	
	with "comment extraction" do
		let(:path) {File.expand_path(".fixtures/comments.rb", __dir__)}
		
		it "should preserve comment indentation" do
			# Should have definitions with comments
			definitions_with_comments = definitions.select do |definition|
				definition.documented?
			end
			expect(definitions_with_comments.size).to be > 0
		end
		
		it "should handle comments correctly" do
			# Should extract comments properly
			definitions.each do |definition|
				if definition.documented?
					expect(definition.comments).to be_a(Array)
					expect(definition.comments.first).to be_a(String)
				end
			end
		end
		
		it "should extract clean comments without hash symbols" do		# Find the method definition
			method_definition = definitions.find{|definition| definition.name == :method}
			expect(method_definition).not.to be_nil
			expect(method_definition.documented?).to be_truthy
			
			# Check the raw comments array - should be clean without leading `#`:
			expect(method_definition.comments.size).to be > 0
			
			# Check that comments don't start with "# " or "#":
			method_definition.comments.each do |comment|
				expect(comment.start_with?("# ")).to be == false
				expect(comment.start_with?("#")).to be == false
			end
			
			# Test Documentation class:
			documentation = method_definition.documentation
			expect(documentation).not.to be_nil
			
			# Documentation should also have clean comments:
			expect(documentation.comments).to be == method_definition.comments
		end
	end
	
	with "adjacent comment extraction" do
		let(:path) {File.expand_path(".fixtures/adjacent_comments.rb", __dir__)}
		let(:source) {Decode::Source.new(path, language)}
		let(:definitions) {language.definitions_for(source).to_a}
		
		it "should only extract adjacent comments" do
			# Find the documented_method:
			documented_method = definitions.find{|definition| definition.name == :documented_method}
			expect(documented_method).not.to be_nil
			
			# Should only have the 2 adjacent comments (lines 10-11):
			expect(documented_method.comments.size).to be == 2
			expect(documented_method.comments[0]).to be == "This is the actual method comment"
			expect(documented_method.comments[1]).to be == "that SHOULD be included."
			
			# Find the another_method:
			another_method = definitions.find{|definition| definition.name == :another_method}
			expect(another_method).not.to be_nil
			
			# Should only have the 1 adjacent comment (line 16):
			expect(another_method.comments.size).to be == 1
			expect(another_method.comments[0]).to be == "This is another method comment"
		end
	end
end
