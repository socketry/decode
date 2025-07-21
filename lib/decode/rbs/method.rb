# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "rbs"
require "console"
require_relative "wrapper"
require_relative "type"

module Decode
	module RBS
		# Represents a Ruby method definition wrapper for RBS generation.
		class Method < Wrapper
			# Initialize a new method wrapper.
			# @parameter definition [Decode::Definition] The method definition to wrap.
			def initialize(definition)
				super
				@signatures = nil
				@keyword_arguments = nil
				@return_type = nil
				@parameters = nil
			end
			
			# Extract method signatures from the method definition.
			# @returns [Array] The extracted signatures for this method.
			def signatures
				@signatures ||= extract_signatures
			end
			
			# Extract keyword arguments from the method definition.
			# @returns [Hash] Hash with :required and :optional keys.
			def keyword_arguments
				@keyword_arguments ||= extract_keyword_arguments(@definition, nil)
			end
			
			# Extract return type from the method definition.
			# @returns [::RBS::Types::t] The RBS return type.
			def return_type
				@return_type ||= extract_return_type(@definition, nil) || ::RBS::Parser.parse_type("untyped")
			end
			
			# Extract parameters from the method definition.
			# @returns [Array] Array of RBS parameter objects.
			def parameters
				@parameters ||= extract_parameters(@definition, nil)
			end
			
			# Convert the method definition to RBS AST
			def to_rbs_ast(index = nil)
				method_name = @definition.name
				comment = self.comment
				
				overloads = []
				if signatures.any?
					signatures.each do |signature_string|
						method_type = ::RBS::Parser.parse_method_type(signature_string)
						overloads << ::RBS::AST::Members::MethodDefinition::Overload.new(
							method_type: method_type,
							annotations: []
						)
					end
				else
					return_type = self.return_type
					
					# Get parameters using AST-based detection
					if ast_function = build_function_type_from_ast(@definition, index)
						method_type = ::RBS::MethodType.new(
							type_params: [],
							type: ast_function,
							block: extract_block_type(@definition, index),
							location: nil
						)
					else
						# Fall back to documentation-based approach
						parameters = self.parameters
						keywords = self.keyword_arguments
						block_type = extract_block_type(@definition, index)
						
						method_type = ::RBS::MethodType.new(
							type_params: [],
							type: ::RBS::Types::Function.new(
								required_positionals: parameters,
								optional_positionals: [],
								rest_positionals: nil,
								trailing_positionals: [],
								required_keywords: keywords[:required],
								optional_keywords: keywords[:optional],
								rest_keywords: nil,
								return_type: return_type
							),
							block: block_type,
							location: nil
						)
					end
					
					overloads << ::RBS::AST::Members::MethodDefinition::Overload.new(
						method_type: method_type,
						annotations: []
					)
				end
				
				kind = @definition.receiver ? :singleton : :instance
				
				::RBS::AST::Members::MethodDefinition.new(
				name: method_name.to_sym,
				kind: kind,
				overloads: overloads,
				annotations: [],
				location: nil,
				comment: comment,
				overloading: false,
				visibility: @definition.visibility || :public
			)
			end
			
			# Build a complete RBS function type from AST information.
			# @parameter definition [Definition] The method definition.
			# @parameter index [Index] The index for context.
			# @returns [RBS::Types::Function] The complete function type, or nil if no AST.
			def build_function_type_from_ast(definition, index)
				node = definition.node
				# Only return nil if we don't have an AST node at all
				return nil unless node&.respond_to?(:parameters)
				
				doc_types = extract_documented_parameter_types(definition)
				
				required_positionals = []
				optional_positionals = []
				rest_positionals = nil
				required_keywords = {}
				optional_keywords = {}
				keyword_rest = nil
				
				# Only process parameters if the node actually has them:
				if node.parameters
					# Handle required positional parameters:
					if node.parameters.respond_to?(:requireds) && node.parameters.requireds
						node.parameters.requireds.each do |param|
							name = param.name
							type = doc_types[name.to_s] || ::RBS::Parser.parse_type("untyped")
							
							required_positionals << ::RBS::Types::Function::Param.new(
								type: type,
								name: name.to_sym
							)
						end
					end
					
					# Handle optional positional parameters (with defaults):
					if node.parameters.respond_to?(:optionals) && node.parameters.optionals
						node.parameters.optionals.each do |param|
							name = param.name
							# For optional parameters, use the documented type as-is (don't make it nullable):
							type = doc_types[name.to_s] || ::RBS::Parser.parse_type("untyped")
							
							optional_positionals << ::RBS::Types::Function::Param.new(
								type: type,
								name: name.to_sym
							)
						end
					end
					
					# Handle rest parameter (*args):
					if node.parameters.respond_to?(:rest) && node.parameters.rest
						rest_param = node.parameters.rest
						name = rest_param.respond_to?(:name) && rest_param.name ? rest_param.name : :args
						base_type = doc_types[name.to_s] || ::RBS::Parser.parse_type("untyped")
						
						rest_positionals = ::RBS::Types::Function::Param.new(
							type: base_type,
							name: name.to_sym
						)
					end
					
					# Handle keyword parameters:
					if node.parameters.respond_to?(:keywords) && node.parameters.keywords
						node.parameters.keywords.each do |param|
							name = param.name
							type = doc_types[name.to_s] || ::RBS::Parser.parse_type("untyped")
							
							if param.respond_to?(:value) && param.value
								# Has default value - optional keyword:
								optional_keywords[name.to_sym] = type
							else
								# No default value - required keyword:
								required_keywords[name.to_sym] = type
							end
						end
					end
					
					# Handle keyword rest parameter (**kwargs):
					if node.parameters.respond_to?(:keyword_rest) && node.parameters.keyword_rest
						rest_param = node.parameters.keyword_rest
						if rest_param.respond_to?(:name) && rest_param.name
							name = rest_param.name
							base_type = doc_types[name.to_s] || ::RBS::Parser.parse_type("untyped")
							
							keyword_rest = ::RBS::Types::Function::Param.new(
								type: base_type,
								name: name.to_sym
							)
						end
					end
				end
				
				return_type = extract_return_type(@definition, index) || ::RBS::Parser.parse_type("untyped")
				
				::RBS::Types::Function.new(
					required_positionals: required_positionals,
					optional_positionals: optional_positionals,
					rest_positionals: rest_positionals,
					trailing_positionals: [],
					required_keywords: required_keywords,
					optional_keywords: optional_keywords,
					rest_keywords: keyword_rest,
					return_type: return_type
				)
			end
			
			private
			
			def extract_signatures
				extract_tags.select(&:method_signature?).map(&:method_signature)
			end
			
			# Extract return type from method documentation.
			def extract_return_type(definition, index)
				# Look for @returns tags in the method's documentation:
				documentation = definition.documentation
				
				# Find all @returns tags:
				returns_tags = documentation&.filter(Decode::Comment::Returns)&.to_a
				
				if returns_tags&.any?
					if returns_tags.length == 1
						# Single return type:
						type_string = returns_tags.first.type.strip
						Type.parse(type_string)
					else
						# Multiple return types - create union:
						types = returns_tags.map do |tag|
							type_string = tag.type.strip
							Type.parse(type_string)
						end
						
						::RBS::Types::Union.new(types: types, location: nil)
					end
				else
					# Infer return type based on method name patterns:
					infer_return_type(definition)
				end
			end
			
			# Extract parameter types from method documentation.
			def extract_parameters(definition, index)
				# Try AST-based extraction first:
				if ast_params = extract_parameters_from_ast(definition)
					return ast_params unless ast_params.empty?
				end
				
				# Fall back to documentation-based extraction:
				documentation = definition.documentation
				return [] unless documentation
				
				# Find @parameter tags (but not @option tags, which are handled separately):
				param_tags = documentation.filter(Decode::Comment::Parameter).to_a
				param_tags = param_tags.reject {|tag| tag.is_a?(Decode::Comment::Option)}
				return [] if param_tags.empty?
				
				param_tags.map do |tag|
					name = tag.name
					type_string = tag.type.strip
					type = Type.parse(type_string)
					
					::RBS::Types::Function::Param.new(
						type: type,
						name: name.to_sym
					)
				end
			end
			
			# Extract parameter information from the Prism AST node.
			# @parameter definition [Definition] The method definition with AST node.
			# @returns [Array] Array of RBS parameter objects, or nil if no AST available.
			def extract_parameters_from_ast(definition)
				node = definition.node
				return nil unless node&.respond_to?(:parameters) && node.parameters
				
				params = []
				doc_types = extract_documented_parameter_types(definition)
				
				# Handle required positional parameters:
				if node.parameters.respond_to?(:requireds) && node.parameters.requireds
					node.parameters.requireds.each do |param|
						name = param.name
						type = doc_types[name.to_s] || ::RBS::Parser.parse_type("untyped")
						
						params << ::RBS::Types::Function::Param.new(
							type: type,
							name: name.to_sym
						)
					end
				end
				
				# Handle optional positional parameters (with defaults):
				if node.parameters.respond_to?(:optionals) && node.parameters.optionals
					node.parameters.optionals.each do |param|
						name = param.name
						# For optional parameters, make the documented type optional if not already:
						base_type = doc_types[name.to_s] || ::RBS::Parser.parse_type("untyped")
						type = make_type_optional_if_needed(base_type)
						
						params << ::RBS::Types::Function::Param.new(
							type: type,
							name: name.to_sym
						)
					end
				end
				
				# Handle rest parameter (*args):
				if node.parameters.respond_to?(:rest) && node.parameters.rest
					rest_param = node.parameters.rest
					name = rest_param.respond_to?(:name) && rest_param.name ? rest_param.name : :args
					base_type = doc_types[name.to_s] || ::RBS::Parser.parse_type("untyped")
					# Rest parameters should be `Array[T]`:
					array_type = ::RBS::Types::ClassInstance.new(
						name: ::RBS::TypeName.new(name: :Array, namespace: ::RBS::Namespace.empty),
						args: [base_type],
						location: nil
					)
					
					params << ::RBS::Types::Function::Param.new(
						type: array_type,
						name: name.to_sym
					)
				end
				
				params
			end
			
			# Extract keyword arguments from @option tags and AST.
			def extract_keyword_arguments(definition, index)
				# Try AST-based extraction first:
				if ast_keywords = extract_keyword_arguments_from_ast(definition)
					return ast_keywords
				end
				
				# Fall back to documentation-based extraction:
				documentation = definition.documentation
				return { required: {}, optional: {} } unless documentation
				
				# Find @option tags:
				option_tags = documentation.filter(Decode::Comment::Option).to_a
				return { required: {}, optional: {} } if option_tags.empty?
				
				keywords = { required: {}, optional: {} }
				
				option_tags.each do |tag|
					name = tag.name.to_s
					# Remove leading colon if present (e.g., ":cached" -> "cached"):
					name = name.sub(/\A:/, "")
					
					type_string = tag.type.strip
					type = Type.parse(type_string)
					
					# Determine if the keyword is optional based on the type annotation.
					# If the type is nullable (contains nil or ends with ?), make it optional:
					if Type.nullable?(type)
						keywords[:optional][name.to_sym] = type
					else
						keywords[:required][name.to_sym] = type
					end
				end
				
				keywords
			end
			
			# Extract keyword arguments from the Prism AST node.
			# @parameter definition [Definition] The method definition with AST node.
			# @returns [Hash] Hash with :required and :optional keyword arguments, or nil if no AST.
			def extract_keyword_arguments_from_ast(definition)
				node = definition.node
				return nil unless node&.respond_to?(:parameters) && node.parameters
				
				required = {}
				optional = {}
				doc_types = extract_documented_parameter_types(definition)
				
				# Handle keyword parameters:
				if node.parameters.respond_to?(:keywords) && node.parameters.keywords
					node.parameters.keywords.each do |param|
						name = param.name
						base_type = doc_types[name.to_s] || ::RBS::Parser.parse_type("untyped")
						
						if param.respond_to?(:value) && param.value
							# Has default value - optional keyword:
							type = make_type_optional_if_needed(base_type)
							optional[name.to_sym] = type
						else
							# No default value - required keyword:
							required[name.to_sym] = base_type
						end
					end
				end
				
				# Handle keyword rest parameter (**kwargs):
				if node.parameters.respond_to?(:keyword_rest) && node.parameters.keyword_rest
					rest_param = node.parameters.keyword_rest
					if rest_param.respond_to?(:name) && rest_param.name
						name = rest_param.name
						base_type = doc_types[name.to_s] || ::RBS::Parser.parse_type("untyped")
						# Keyword rest should be `Hash[Symbol, T]`:
						hash_type = ::RBS::Types::ClassInstance.new(
							name: ::RBS::TypeName.new(name: :Hash, namespace: ::RBS::Namespace.empty),
							args: [
								::RBS::Types::ClassInstance.new(name: ::RBS::TypeName.new(name: :Symbol, namespace: ::RBS::Namespace.empty), args: [], location: nil),
								base_type
							],
							location: nil
						)
						optional[name.to_sym] = hash_type
					end
				end
				
				{ required: required, optional: optional }
			end
			
			# Extract documented parameter types into a hash for lookup.
			# @parameter definition [Definition] The method definition.
			# @returns [Hash] Map of parameter name to RBS type.
			def extract_documented_parameter_types(definition)
				doc_types = {}
				documentation = definition.documentation
				return doc_types unless documentation
				
				# Extract types from @parameter tags:
				param_tags = documentation.filter(Decode::Comment::Parameter).to_a
				param_tags.each do |tag|
					doc_types[tag.name] = Type.parse(tag.type.strip)
				end
				
				# Extract types from @option tags  
				option_tags = documentation.filter(Decode::Comment::Option).to_a
				option_tags.each do |tag|
					# Remove leading colon:
					name = tag.name.sub(/\A:/, "")
					doc_types[name] = Type.parse(tag.type.strip)
				end
				
				doc_types
			end
			
			# Make a type optional if it's not already nullable.
			# @parameter type [RBS::Types::t] The base type.
			# @returns [RBS::Types::t] The optionally-nullable type.
			def make_type_optional_if_needed(type)
				return type if Type.nullable?(type)
				
				# Create a union with nil to make it optional:
				::RBS::Types::Union.new(
					types: [type, ::RBS::Types::Bases::Nil.new(location: nil)],
					location: nil
				)
			end
			
			
			# Extract block type from method documentation.
			def extract_block_type(definition, index)
				documentation = definition.documentation
				return nil unless documentation
				
				# Find `@yields` tags:
				yields_tag = documentation.filter(Decode::Comment::Yields).first
				return nil unless yields_tag
				
				# Extract block parameters from nested `@parameter` tags:
				block_params = yields_tag.filter(Decode::Comment::Parameter).map do |param_tag|
					name = param_tag.name
					type_string = param_tag.type.strip
					type = Type.parse(type_string)
					
					::RBS::Types::Function::Param.new(
						type: type,
						name: name.to_sym
					)
				end
				
				# Parse the block signature to determine if it's required.
				# Check both the directive name and the block signature:
				block_signature = yields_tag.block
				directive_name = yields_tag.directive
				required = !directive_name.include?("?") && !block_signature.include?("?") && !block_signature.include?("optional")
				
				# Determine block return type (default to `void` if not specified):
				block_return_type = ::RBS::Parser.parse_type("void")
				
				# Create the block function type:
				block_function = ::RBS::Types::Function.new(
					required_positionals: block_params,
					optional_positionals: [],
					rest_positionals: nil,
					trailing_positionals: [],
					required_keywords: {},
					optional_keywords: {},
					rest_keywords: nil,
					return_type: block_return_type
				)
				
				# Create and return the block type:
				::RBS::Types::Block.new(
					type: block_function,
					required: required,
					self_type: nil
				)
			end
			
			# Infer return type based on method patterns and heuristics.
			def infer_return_type(definition)
				method_name = definition.name
				method_name_str = method_name.to_s
				
				# Methods ending with `?` are typically boolean:
				if method_name_str.end_with?("?")
					return ::RBS::Parser.parse_type("bool")
				end
				
				# Methods named `initialize` return `void`:
				if method_name == :initialize
					return ::RBS::Parser.parse_type("void")
				end
				
				# Methods with names that suggest they return `self`:
				if method_name_str.match?(/^(add|append|prepend|push|<<|concat|merge!|sort!|reverse!|clear|delete|remove)/)
					return ::RBS::Parser.parse_type("self")
				end
				
				# Default to `untyped`:
				::RBS::Parser.parse_type("untyped")
			end
		end
	end
end
