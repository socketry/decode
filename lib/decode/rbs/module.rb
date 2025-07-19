# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "rbs"
require_relative "wrapper"

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
			def to_rbs_ast(method_definitions = [], index = nil)
				name = simple_name_to_rbs(@definition.name)
				comment = self.comment
				
				# Build method definitions
				methods = method_definitions.map{|method_def| Method.new(method_def).to_rbs_ast(index)}.compact
				
				::RBS::AST::Declarations::Module.new(
					name: name,
					type_params: [],
					self_types: [],
					members: methods,
					annotations: [],
					location: nil,
					comment: comment
				)
			end
			
			private
			
			# Convert a simple name to RBS TypeName (not qualified)
			def simple_name_to_rbs(name)
				::RBS::TypeName.new(name: name.to_sym, namespace: ::RBS::Namespace.empty)
			end
			
		end
	end
end 
