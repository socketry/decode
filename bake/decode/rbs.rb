# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

def initialize(...)
	super
	
	require "decode/rbs"
end

# Generate RBS declarations for the given source root.
# @parameter root [String] The root path to index.
def generate(root)
	index = Decode::Index.for(root)
	generator = Decode::RBS::Generator.new(include_private: true)
	generator.generate(index)
end
