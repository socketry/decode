# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require "decode/source"
require "decode/language/ruby"

describe Decode::Comment::Text do
	let(:language) {Decode::Language::Ruby.new}
	let(:source) {Decode::Source.new(path, language)}
	let(:documentation) {source.segments.first.documentation}
	
	with "nested text nodes" do
		let(:path) {File.expand_path(".fixtures/text.rb", __dir__)}
		
		it "should have text nodes" do
			expect(documentation.children[0]).to be_a(Decode::Comment::Text)
			expect(documentation.children[0]).to have_attributes(
				line: be == "Iterates over all the items."
			)
			
			yields = documentation.children[1]
			expect(yields).to be_a(Decode::Comment::Yields)
			expect(yields.children[0]).to be_a(Decode::Comment::Text)
			expect(yields.children[0]).to have_attributes(
				line: be == "The items if a block is given."
			)
			
			parameter = yields.children[2]
			expect(parameter).to be_a(Decode::Comment::Parameter)
			
			expect(parameter.children[0]).to be_a(Decode::Comment::Text)
			expect(parameter.children[0]).to have_attributes(
				line: be == "\t\tThe item will always be negative."
			)
		end
		
		it "can extract top level text" do
			expect(documentation.text).to be == [
				"Iterates over all the items.",
				"For more details see ruby:`Array`.",
			]
		end
	end
	
	with "indented code" do
		let(:path) {File.expand_path(".fixtures/text.rb", __dir__)}
		let(:documentation) {source.segments.to_a[1].documentation}
		
		it "should have text nodes" do
			expect(documentation.children[0]).to be_a(Decode::Comment::Text)
			expect(documentation.children[0]).to have_attributes(
				line: be == "Indented code:"
			)
			
			expect(documentation.children[1]).to be_a(Decode::Comment::Text)
			expect(documentation.children[1]).to have_attributes(
				line: be == "``` ruby"
			)
			
			expect(documentation.children[2]).to be_a(Decode::Comment::Text)
			expect(documentation.children[2]).to have_attributes(
				line: be == "def indentation"
			)
			
			expect(documentation.children[3]).to be_a(Decode::Comment::Text)
			expect(documentation.children[3]).to have_attributes(
				line: be == "\treturn \"Hello World!\""
			)
			
			expect(documentation.children[4]).to be_a(Decode::Comment::Text)
			expect(documentation.children[4]).to have_attributes(
				line: be == "end"
			)
			
			expect(documentation.children[5]).to be_a(Decode::Comment::Text)
			expect(documentation.children[5]).to have_attributes(
				line: be == "```"
			)
		end
		
		it "can extract top level text" do
			expect(documentation.text).to be == [
				"Indented code:",
				"``` ruby",
				"def indentation",
				"\treturn \"Hello World!\"",
				"end",
				"```",
			]
		end
	end
end
