# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "rbs"
require_relative "wrapper"
require_relative "method"
require_relative "type"

module Decode
	module RBS
		# Represents a Ruby module definition wrapper for RBS generation.
		class Module < Wrapper
			
			# Initialize a new module wrapper.
			# @parameter definition [Decode::Definition] The module definition to wrap.
			def initialize(definition)
				super
			end
			
			# Convert the module definition to RBS AST
			# @parameter method_definitions [Array(Method)] The method definitions to convert.
			# @parameter constant_definitions [Array(Constant)] The constant definitions to convert.
			# @parameter attribute_definitions [Array(Attribute)] The attribute definitions to convert.
			# @parameter index [Index?] The index for resolving references.
			# @returns [RBS::AST::Declarations::Module] The RBS AST for the module.
			def to_rbs_ast(method_definitions = [], constant_definitions = [], attribute_definitions = [], index = nil)
				name = simple_name_to_rbs(@definition.name)
				comment = self.comment
				
				# Build method definitions
				methods = method_definitions.map{|method_def| Method.new(method_def).to_rbs_ast(index)}.compact
				
				# Build constant definitions:
				constants = constant_definitions.map{|const_def| build_constant_rbs(const_def)}.compact
				
				# Build attribute definitions and infer instance variable types:
				attributes, instance_variables = build_attributes_rbs(attribute_definitions)
				
				::RBS::AST::Declarations::Module.new(
					name: name,
					type_params: [],
					self_types: [],
					members: constants + attributes + instance_variables + methods,
					annotations: [],
					location: nil,
					comment: comment
				)
			end
			
			private
			
			# Build a constant RBS declaration.
			def build_constant_rbs(constant_definition)
				# Look for @constant tags in the constant's documentation:
				documentation = constant_definition.documentation
				constant_tags = documentation&.filter(Decode::Comment::Constant)&.to_a
				
				if constant_tags&.any?
					type_string = constant_tags.first.type.strip
					type = ::Decode::RBS::Type.parse(type_string)
					
					::RBS::AST::Declarations::Constant.new(
					name: constant_definition.name.to_sym,
					type: type,
					location: nil,
					comment: nil
				)
				end
			end
			
			# Convert a simple name to RBS TypeName (not qualified).
			def simple_name_to_rbs(name)
				::RBS::TypeName.new(name: name.to_sym, namespace: ::RBS::Namespace.empty)
			end
			
			# Build attribute RBS declarations and infer instance variable types.
			# @parameter attribute_definitions [Array] Array of Attribute definition objects
			# @returns [Array] A tuple of [attribute_declarations, instance_variable_declarations]
			def build_attributes_rbs(attribute_definitions)
				attributes = []
				instance_variables = []
				
				# Create a mapping from attribute names to their types:
				attribute_types = {}
				
				attribute_definitions.each do |attribute_definition|
					# Extract @attribute type annotation from documentation:
					documentation = attribute_definition.documentation
					attribute_tags = documentation&.filter(Decode::Comment::Attribute)&.to_a
					
					if attribute_tags&.any?
						type_string = attribute_tags.first.type.strip
						type = ::Decode::RBS::Type.parse(type_string)
						
						attribute_types[attribute_definition.name] = type
						
						# Generate attr_reader RBS declaration:
						attributes << ::RBS::AST::Members::AttrReader.new(
							name: attribute_definition.name.to_sym,
							type: type,
							ivar_name: :"@#{attribute_definition.name}",
							kind: :instance,
							annotations: [],
							location: nil,
							comment: nil
						)
						
						# Generate instance variable declaration:
						instance_variables << ::RBS::AST::Members::InstanceVariable.new(
							name: :"@#{attribute_definition.name}",
							type: type,
							location: nil,
							comment: nil
						)
					end
				end
				
				[attributes, instance_variables]
			end
		end
	end
end
