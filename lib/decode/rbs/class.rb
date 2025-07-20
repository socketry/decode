# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "rbs"
require_relative "wrapper"
require_relative "method"
module Decode
	module RBS
		# Represents a Ruby class definition wrapper for RBS generation.
		class Class < Wrapper
			
			# Initialize a new class wrapper.
			# @parameter definition [Decode::Definition] The class definition to wrap.
			def initialize(definition)
				super
				@generics = nil
			end
			
			# Extract generic type parameters from the class definition.
			# @returns [Array[Symbol]] The generic type parameters for this class.
			def generics
				@generics ||= extract_generics
			end
			
			# Convert the class definition to RBS AST
			def to_rbs_ast(method_definitions = [], constant_definitions = [], attribute_definitions = [], index = nil)
				name = simple_name_to_rbs(@definition.name)
				comment = self.comment
				
				# Extract generics from RBS tags
				type_params = generics.map do |generic|
					::RBS::AST::TypeParam.new(
						name: generic.to_sym,
						variance: nil,
						upper_bound: nil,
						location: nil
					)
				end
				
				# Build method definitions:
				methods = method_definitions.map{|method_def| Method.new(method_def).to_rbs_ast(index)}.compact
				
				# Build constant definitions:
				constants = constant_definitions.map{|const_def| build_constant_rbs(const_def)}.compact
				
				# Build attribute definitions and infer instance variable types:
				attributes, instance_variables = build_attributes_rbs(attribute_definitions)
				
				# Extract super class if present:
				super_class = if @definition.super_class
					::RBS::AST::Declarations::Class::Super.new(
								name: qualified_name_to_rbs(@definition.super_class),
								args: [],
								location: nil
							)
				end
				
				# Create the class declaration with generics:
				::RBS::AST::Declarations::Class.new(
					name: name,
					type_params: type_params,
					super_class: super_class,
					members: constants + attributes + instance_variables + methods,
					annotations: [],
					location: nil,
					comment: comment
				)
			end
			
			private
			
			def extract_generics
				tags.select(&:generic?).map(&:generic_parameter)
			end
			
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
				
				attribute_definitions.each do |attr_def|
					# Extract @attribute type annotation from documentation:
					documentation = attr_def.documentation
					attribute_tags = documentation&.filter(Decode::Comment::Attribute)&.to_a
					
					if attribute_tags&.any?
						type_string = attribute_tags.first.type.strip
						type = ::Decode::RBS::Type.parse(type_string)
						
						attribute_types[attr_def.name] = type
						
						# Generate attr_reader RBS declaration:
						attributes << ::RBS::AST::Members::AttrReader.new(
							name: attr_def.name.to_sym,
							type: type,
							ivar_name: :"@#{attr_def.name}",
							kind: :instance,
							annotations: [],
							location: nil,
							comment: nil
						)
						
						# Generate instance variable declaration:
						instance_variables << ::RBS::AST::Members::InstanceVariable.new(
							name: :"@#{attr_def.name}",
							type: type,
							location: nil,
							comment: nil
						)
					end
				end
				
				[attributes, instance_variables]
			end
			
			# Convert a qualified name to RBS TypeName
			def qualified_name_to_rbs(qualified_name)
				parts = qualified_name.split("::")
				name = parts.pop
				
				# For simple names (no ::), create relative references within current namespace:
				if parts.empty?
					::RBS::TypeName.new(name: name.to_sym, namespace: ::RBS::Namespace.empty)
				else
					# For qualified names within the same root namespace, use relative references.
					# This handles cases like `Comment::Node`, `Language::Generic` within `Decode` module.
					namespace = ::RBS::Namespace.new(path: parts.map(&:to_sym), absolute: false)
					::RBS::TypeName.new(name: name.to_sym, namespace: namespace)
				end
			end
			
		end
	end
end
