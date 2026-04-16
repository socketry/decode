# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "decode/language/ruby"
require "decode/source"

describe Decode::Language::Ruby do
	let(:language) {Decode::Language::Ruby.new}
	let(:source) {Decode::Source.new("test/decode/language/ruby/.fixtures/mixins.rb", language)}
	
	it "extracts include, extend, and prepend mixins for classes and modules" do
		definitions = language.definitions_for(source).to_a
		
		my_module = definitions.find{|d| d.is_a?(Decode::Language::Ruby::Module) && d.qualified_name == "Mixins::Greeting"}
		expect(my_module).not.to be_nil
		
		my_class = definitions.find{|d| d.is_a?(Decode::Language::Ruby::Class) && d.qualified_name == "Mixins::Greeter"}
		expect(my_class).not.to be_nil
		
		expect(my_class.includes).to be == ["Mixins::Greeting"]
		expect(my_class.extends).to be == ["Mixins::Greeting"]
		expect(my_class.prepends).to be == ["Mixins::Greeting"]
	end
end
