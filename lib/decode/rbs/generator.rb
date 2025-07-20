# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "rbs"
require_relative "../index"
require_relative "class"
require_relative "module"

module Decode
	module RBS
		# Represents a generator for RBS type declarations.
		class Generator
			# Initialize a new RBS generator.
			# Sets up the RBS environment for type resolution.
			# @parameter include_private [bool] Whether to include private methods in RBS output.
			def initialize(include_private: false)
				# Set up RBS environment for type resolution
				@loader = ::RBS::EnvironmentLoader.new()
				@environment = ::RBS::Environment.from_loader(@loader).resolve_type_names
				@include_private = include_private
			end
			
			# @attribute [::RBS::EnvironmentLoader] The RBS environment loader.
			attr :loader
			
			# @attribute [::RBS::Environment] The resolved RBS environment.
			attr :environment
			
			# @attribute [bool] Whether to include private methods.
			attr :include_private
			
			# Generate RBS declarations for the given index.
			# @parameter index [Decode::Index] The index containing definitions to generate RBS for.
			# @parameter output [IO] The output stream to write to.
			def generate(index, output: $stdout)
				# Build nested RBS AST structure using a hash for proper ||= behavior
				declarations = {} #: Hash[Array[Symbol], untyped]
				roots = {} #: Hash[Array[Symbol], untyped]
				
				# Efficiently traverse the trie to find containers and their methods
				index.trie.traverse do |lexical_path, node, descend|
					# Process container definitions at this node
					if node.values
						containers = node.values.select{|definition| definition.container? && definition.public?}
						containers.each do |definition|
							case definition
							when Decode::Language::Ruby::Class, Decode::Language::Ruby::Module
								if declaration = build_nested_declaration(definition, declarations, index)
									roots[definition.qualified_name] ||= declaration
								end
							end
						end
					end
					
					# Continue traversing children
					descend.call
				end
				
				# Write the RBS output
				writer = ::RBS::Writer.new(out: output)
				
				unless roots.empty?
					writer.write(roots.values)
				end
			end
			
			private
			
			# Build nested RBS declarations preserving the parent hierarchy.
			# @parameter definition [Definition] The definition to build RBS for.
			# @parameter declarations [Hash] The declarations hash to store results.
			# @parameter index [Index] The index containing all definitions.
			# @returns [untyped?] If the definition has no parent, returns the declaration, otherwise nil.
			def build_nested_declaration(definition, declarations, index)
				# Create the declaration for this definition using ||= to avoid duplicates
				qualified_name = definition.qualified_name
				declaration = (declarations[qualified_name] ||= definition_to_rbs(definition, index))
				
				# Add this declaration to its parent's members if it has a parent
				if definition.parent
					parent_qualified_name = definition.parent.qualified_name
					parent_container = declarations[parent_qualified_name]
					
					# Only add if not already present
					unless parent_container.members.any?{|member| member.respond_to?(:name) && member.name.name == definition.name.to_sym}
						parent_container.members << declarations[qualified_name]
					end
					
					return nil
				else
					return declaration
				end
			end
			
			# Convert a definition to RBS AST.
			# @parameter definition [Definition] The definition to convert.
			# @parameter index [Index] The index containing all definitions.
			# @returns [untyped] The RBS AST declaration.
			def definition_to_rbs(definition, index)
				methods = get_methods_for_definition(definition, index)
				constants = get_constants_for_definition(definition, index)
				attributes = get_attributes_for_definition(definition, index)
				
				case definition
				when Decode::Language::Ruby::Class
					Class.new(definition).to_rbs_ast(methods, constants, attributes, index)
				when Decode::Language::Ruby::Module  
					Module.new(definition).to_rbs_ast(methods, constants, attributes, index)
				end
			end
			
			# Get methods for a given definition efficiently using trie lookup.
			# @parameter definition [Definition] The definition to get methods for.
			# @parameter index [Index] The index containing all definitions.
			# @returns [Array] Array of method definitions.
			def get_methods_for_definition(definition, index)
				# Use the trie to efficiently find methods for this definition
				if node = index.trie.lookup(definition.full_path)
					node.children.flat_map do |name, child|
						child.values.select do |symbol| 
							symbol.is_a?(Decode::Language::Ruby::Method) && 
							(symbol.public? || symbol.protected? || (@include_private && symbol.private?))
						end
					end
				else
					[]
				end
			end
			
			# Get constants for a given definition efficiently using trie lookup.
			# @parameter definition [Definition] The definition to get constants for.
			# @parameter index [Index] The index containing all definitions.
			# @returns [Array] Array of constant definitions.
			def get_constants_for_definition(definition, index)
				# Use the trie to efficiently find constants for this definition
				if node = index.trie.lookup(definition.full_path)
					node.children.flat_map do |name, child|
						child.values.select{|symbol| symbol.is_a?(Decode::Language::Ruby::Constant)}
					end
				else
					[]
				end
			end
			
			# Get attributes for a given definition efficiently using trie lookup.
			# @parameter definition [Definition] The definition to get attributes for.
			# @parameter index [Index] The index containing all definitions.
			# @returns [Array] Array of attribute definitions.
			def get_attributes_for_definition(definition, index)
				# Use the trie to efficiently find attributes for this definition
				if node = index.trie.lookup(definition.full_path)
					node.children.flat_map do |name, child|
						child.values.select{|symbol| symbol.is_a?(Decode::Language::Ruby::Attribute)}
					end
				else
					[]
				end
			end
		end
	end
end
