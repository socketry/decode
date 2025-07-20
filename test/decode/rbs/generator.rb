# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "decode/rbs"
require "decode/index"
require "tmpdir"

describe Decode::RBS::Generator do
	let(:generator) {subject.new}
	
	def create_or_compare(fixture_name, actual_output)
		fixture_path = File.expand_path(".fixtures/#{fixture_name}", __dir__)
		expected_path = "#{fixture_path}.rbs"
		
		if File.exist?(expected_path)
			# Compare with existing expected output
			expected_output = File.read(expected_path)
			expect(actual_output.strip).to be == expected_output.strip
		else
			# Create the expected output file
			File.write(expected_path, actual_output)
			inform "Created expected output: #{expected_path}"
		end
	end
	
	def generate_rbs_for_fixture(fixture_name)
		fixture_path = File.expand_path(".fixtures/#{fixture_name}.rb", __dir__)
		index = Decode::Index.for(fixture_path)
		
		output = StringIO.new
		generator.generate(index, output: output)
		output.string
	end
	
	with "#generate" do
		with "basic class" do
			it "generates correct RBS for a basic class" do
				actual_output = generate_rbs_for_fixture("basic_class")
				create_or_compare("basic_class", actual_output)
			end
		end
		
		with "inheritance" do
			it "generates correct RBS for class inheritance" do
				actual_output = generate_rbs_for_fixture("super_class")
				create_or_compare("super_class", actual_output)
			end
		end
		
		with "attribute type inference" do
			it "generates correct RBS for attributes with type annotations" do
				actual_output = generate_rbs_for_fixture("attribute_inference")
				create_or_compare("attribute_inference", actual_output)
			end
		end
		
		with "constant type inference" do
			it "generates correct RBS for constants with type annotations" do
				actual_output = generate_rbs_for_fixture("constant_inference")
				create_or_compare("constant_inference", actual_output)
			end
		end
		
		with "modules" do
			it "generates correct RBS for modules" do
				actual_output = generate_rbs_for_fixture("basic_module")
				create_or_compare("basic_module", actual_output)
			end
		end
		
		with "generics" do
			it "generates correct RBS for generic classes" do
				actual_output = generate_rbs_for_fixture("generics")
				create_or_compare("generics", actual_output)
			end
		end
		
		with "method types" do
			it "generates correct RBS for different method signatures" do
				actual_output = generate_rbs_for_fixture("method_types")
				create_or_compare("method_types", actual_output)
			end
		end
		
		with "empty input" do
			it "handles empty input gracefully" do
				index = Decode::Index.for()
				output = StringIO.new
				generator.generate(index, output: output)
				expect(output.string).to be(:empty?)
			end
		end
		
		with "multiple files" do
			it "can process multiple fixture files together" do
				basic_class_path = File.expand_path(".fixtures/basic_class.rb", __dir__)
				super_class_path = File.expand_path(".fixtures/super_class.rb", __dir__)
				
				index = Decode::Index.for(basic_class_path, super_class_path)
				output = StringIO.new
				generator.generate(index, output: output)
				
				result = output.string
				expect(result).to be(:include?, "class Animal")
				expect(result).to be(:include?, "class Dog < Animal")
			end
		end
	end
end
