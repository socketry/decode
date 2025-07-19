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
					visibility: :public
				)
			end
			
			private
			
			def extract_signatures
				extract_tags.select(&:method_signature?).map(&:method_signature)
			end
			
			# Extract return type from method documentation
			def extract_return_type(definition, index)
				# Look for @returns tags in the method's documentation
				documentation = definition.documentation
				
				# Find all @returns tags
				returns_tags = documentation&.filter(Decode::Comment::Returns)&.to_a
				
				if returns_tags&.any?
					if returns_tags.length == 1
						# Single return type
						type_string = returns_tags.first.type.strip
						Type.parse(type_string)
					else
						# Multiple return types - create union
						types = returns_tags.map do |tag|
							type_string = tag.type.strip
							Type.parse(type_string)
						end
						
						::RBS::Types::Union.new(types: types, location: nil)
					end
				else
					# Infer return type based on method name patterns
					infer_return_type(definition)
				end
			end
			
			# Extract parameter types from method documentation
			def extract_parameters(definition, index)
				documentation = definition.documentation
				return [] unless documentation
				
				# Find @parameter tags (but not @option tags, which are handled separately)
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
			
			# Extract keyword arguments from @option tags
			def extract_keyword_arguments(definition, index)
				documentation = definition.documentation
				return { required: {}, optional: {} } unless documentation
				
				# Find @option tags
				option_tags = documentation.filter(Decode::Comment::Option).to_a
				return { required: {}, optional: {} } if option_tags.empty?
				
				keywords = { required: {}, optional: {} }
				
				option_tags.each do |tag|
					name = tag.name.to_s
					# Remove leading colon if present (e.g., ":cached" -> "cached")
					name = name.sub(/\A:/, "")
					
					type_string = tag.type.strip
					type = Type.parse(type_string)
					
					# Determine if the keyword is optional based on the type annotation
					# If the type is nullable (contains nil or ends with ?), make it optional
					if Type.nullable?(type)
						keywords[:optional][name.to_sym] = type
					else
						keywords[:required][name.to_sym] = type
					end
				end
				
				keywords
			end
			
			
			# Extract block type from method documentation
			def extract_block_type(definition, index)
				documentation = definition.documentation
				return nil unless documentation
				
				# Find @yields tags
				yields_tag = documentation.filter(Decode::Comment::Yields).first
				return nil unless yields_tag
				
				# Extract block parameters from nested @parameter tags
				block_params = yields_tag.filter(Decode::Comment::Parameter).map do |param_tag|
					name = param_tag.name
					type_string = param_tag.type.strip
					type = Type.parse(type_string)
					
					::RBS::Types::Function::Param.new(
						type: type,
						name: name.to_sym
					)
				end
				
				# Parse the block signature to determine if it's required
				# Check both the directive name and the block signature
				block_signature = yields_tag.block
				directive_name = yields_tag.directive
				required = !directive_name.include?("?") && !block_signature.include?("?") && !block_signature.include?("optional")
				
				# Determine block return type (default to void if not specified)
				block_return_type = ::RBS::Parser.parse_type("void")
				
				# Create the block function type
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
				
				# Create and return the block type
				::RBS::Types::Block.new(
					type: block_function,
					required: required,
					self_type: nil
				)
			end
			
			# Infer return type based on method patterns and heuristics
			def infer_return_type(definition)
				method_name = definition.name
				method_name_str = method_name.to_s
				
				# Methods ending with ? are typically boolean
				if method_name_str.end_with?("?")
					return ::RBS::Parser.parse_type("bool")
				end
				
				# Methods named initialize return void
				if method_name == :initialize
					return ::RBS::Parser.parse_type("void")
				end
				
				# Methods with names that suggest they return self
				if method_name_str.match?(/^(add|append|prepend|push|<<|concat|merge!|sort!|reverse!|clear|delete|remove)/)
					return ::RBS::Parser.parse_type("self")
				end
				
				# Default to untyped
				::RBS::Parser.parse_type("untyped")
			end
			
		end
	end
end
