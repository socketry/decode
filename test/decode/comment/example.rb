# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "decode/source"
require "decode/language/ruby"

describe Decode::Comment::Example do
	let(:language) {Decode::Language::Ruby.new}
	let(:source) {Decode::Source.new(path, language)}
	let(:segments) {source.segments.to_a}
	
	with "example with title" do
		let(:path) {File.expand_path(".fixtures/example.rb", __dir__)}
		let(:documentation) {segments[0].documentation}
		
		it "should parse example with title" do
			example = documentation.children.first
			expect(example).to be_a(Decode::Comment::Example)
			expect(example.directive).to be == "example"
			expect(example.title).to be == "Create a new thing"
		end
		
		it "should have example code as children" do
			example = documentation.children.first
			text = example.text
			expect(text).to be_a(Array)
			expect(text.size).to be > 0
		end
	end
	
	with "example without title" do
		let(:path) {File.expand_path(".fixtures/example.rb", __dir__)}
		let(:documentation) {segments[1].documentation}
		
		it "should parse example without title" do
			example = documentation.children.first
			expect(example).to be_a(Decode::Comment::Example)
			expect(example.directive).to be == "example"
			expect(example.title).to be == nil
		end
		
		it "should have code method that returns joined text" do
			example = documentation.children.first
			code = example.code
			expect(code).to be_a(String)
			expect(code.include?("Thing.new")).to be == true
		end
	end
end
