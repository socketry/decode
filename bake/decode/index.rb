# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

def initialize(...)
	super
	
	require "decode/index"
	require "set"
end

# Process the given source root and report on comment coverage.
# @parameter root [String] The root path to index.
def coverage(root)
	index = Decode::Index.for(root)
	
	documented = Set.new
	missing = {}
	
	index.trie.traverse do |path, node, descend|
		public_definition = node.values.nil?
		
		node.values&.each do |definition|
			if definition.coverage_relevant?
				level = path.size
				
				if definition.documented?
					documented << definition.qualified_name
				else
					missing[definition.qualified_name] ||= definition
				end
				
				public_definition = true
			end
		end
		
		# Don't descend into non-public definitions:
		if public_definition
			descend.call
		end
	end
	
	# Since there can be multiple definitions for a given symbol, we can ignore any missing definitions that have been documented elsewhere:
	documented.each do |qualified_name|
		missing.delete(qualified_name)
	end
	
	documented_count = documented.size
	public_count = documented_count + missing.size
	$stderr.puts "#{documented_count} definitions have documentation, out of #{public_count} public definitions."
	
	if documented_count < public_count
		$stderr.puts nil, "Missing documentation for:"
		missing.each do |qualified_name, definition|
			location = definition.location
			if location
				$stderr.puts "- #{qualified_name} (#{location.path}:#{location.line})"
			else
				$stderr.puts "- #{qualified_name}"
			end
		end
		
		raise RuntimeError, "Insufficient documentation!"
	end
end

# Process the given source root and report on symbols.
# @parameter root [String] The root path to index.
def symbols(root)
	index = Decode::Index.for(root)
	
	index.trie.traverse do |path, node, descend|
		level = path.size
		puts "#{"  " * level}#{path.inspect} -> #{node.values.inspect}"
		
		if path.any?
			puts "#{"  " * level}#{path.join("::")}"
		end
		
		descend.call
	end
end

# Print documentation for all definitions.
# @parameter root [String] The root path to index.
def documentation(root)
	index = Decode::Index.for(root)
	
	index.definitions.each do |name, definition|
		comments = definition.comments
		
		if comments
			puts "## `#{name}`"
			puts
			puts comments
			puts
		end
	end
end
