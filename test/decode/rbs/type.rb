# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "decode/rbs/type"

describe Decode::RBS::Type do
	with "#nullable?" do
		it "detects nullable types with question mark suffix" do
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("Boolean?"))).to be == true
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("String?"))).to be == true
		end
		
		it "detects union types with nil" do
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("String | nil"))).to be == true
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("nil | String"))).to be == true
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("Integer | String | nil"))).to be == true
		end
		
		it "detects nested union types with nil" do
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("(String | nil) | Integer"))).to be == true
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("String | (Integer | nil)"))).to be == true
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("((String | nil) | Integer) | Boolean"))).to be == true
		end
		
		it "detects tuple types with nil" do
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("[String?]"))).to be == true
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("[String, Integer?]"))).to be == true
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("[String, Integer]"))).to be == false
		end
		
		it "detects non-nullable types" do
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("Boolean"))).to be == false
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("String"))).to be == false
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("Integer | String"))).to be == false
		end
		
		it "detects direct nil type" do
			expect(Decode::RBS::Type.nullable?(::RBS::Parser.parse_type("nil"))).to be == true
		end
	end
	
	with "#parse" do
		it "parses valid type strings" do
			type = Decode::RBS::Type.parse("String")
			expect(type).to be_a(::RBS::Types::ClassInstance)
			expect(type.name.name).to be == :String
		end
		
		it "handles backwards compatibility transformations" do
			# () -> []
			type = Decode::RBS::Type.parse("Array(Integer)")
			expect(type).to be_a(::RBS::Types::ClassInstance)
			expect(type.name.name).to be == :Array
			
			# | Nil -> ?
			type = Decode::RBS::Type.parse("String | Nil")
			expect(type).to be_a(::RBS::Types::Optional)
			expect(Decode::RBS::Type.nullable?(type)).to be == true
			
			# Boolean -> bool
			type = Decode::RBS::Type.parse("Boolean")
			expect(type).to be_a(::RBS::Types::Bases::Bool)
		end
		
		it "handles invalid type strings gracefully" do
			type = Decode::RBS::Type.parse(":::")  # Invalid RBS syntax
			expect(type).to be_a(::RBS::Types::Bases::Any)  # "untyped" parses to Any type
		end
		
		it "preserves complex union types" do
			type = Decode::RBS::Type.parse("String | Integer | nil")
			expect(type).to be_a(::RBS::Types::Union)
			expect(Decode::RBS::Type.nullable?(type)).to be == true
		end
	end
end 