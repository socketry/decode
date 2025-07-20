# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require "prism"

require_relative "../../scope"

require_relative "alias"
require_relative "attribute"
require_relative "block"
require_relative "call"
require_relative "class"
require_relative "constant"
require_relative "function"
require_relative "method"
require_relative "module"

require_relative "segment"

module Decode
	module Language
		module Ruby
			# The Ruby source code parser.
			class Parser
				# Initialize a new Ruby parser.
				# @parameter language [Language::Generic] The language instance.
				def initialize(language)
					@language = language
					
					@visibility = :public
					@definitions = Hash.new.compare_by_identity
				end
				
				# @attribute [Language::Generic] The language instance.
				attr :language
				
				# @attribute [Symbol] The current visibility mode.
				attr :visibility
				
				# @attribute [Hash] Cache for definition lookups.
				attr :definitions
				
				# Parse the source code using Prism.
				# @parameter source [Source] The source to parse.
				# @returns [untyped] The parsed syntax tree.
				def parse_source(source)
					text = source.read
					return ::Prism.parse(text)
				end
				
				# Extract definitions from the given input file.
				# @parameter source [Source] The source file to parse.
				# @returns [Enumerator[Definition]] An enumerator of definitions.
				def definitions_for(source, &block)
					return enum_for(:definitions_for, source) unless block_given?
					
					result = self.parse_source(source)
					result.attach_comments!
					
					# Pass the source to walk_definitions for location tracking
					source = source.is_a?(Source) ? source : nil
					walk_definitions(result.value, nil, source, &block)
				end
				
				# Walk over the syntax tree and extract relevant definitions with their associated comments.
				# @parameter node [untyped] The syntax tree node to walk.
				# @parameter parent [Definition?] The parent definition.
				# @parameter source [Source?] The source file for location tracking.
				def walk_definitions(node, parent = nil, source = nil, &block)
					# Check for scope definitions from comments
					if node.comments.any?
						parent = scope_for(comments_for(node), parent, &block) || parent
					end
					
					case node.type
					when :program_node
						with_visibility do
							node.child_nodes.each do |child|
								walk_definitions(child, parent, source, &block)
							end
						end
					when :statements_node
						node.child_nodes.each do |child|
							walk_definitions(child, parent, source, &block)
						end
					when :block_node
						if node.body
							walk_definitions(node.body, parent, source, &block)
						end
					when :module_node
						path = nested_path_for(node.constant_path)
						
						definition = Module.new(path,
									visibility: :public,
									comments: comments_for(node),
									parent: parent,
									node: node,
									language: @language,
									source: source,
								)
						
						store_definition(parent, path.last.to_sym, definition)
						yield definition
						
						if body = node.body
							with_visibility do
								walk_definitions(body, definition, source, &block)
							end
						end
					when :class_node
						path = nested_path_for(node.constant_path)
						super_class = nested_name_for(node.superclass)
						
						definition = Class.new(path,
									super_class: super_class,
									visibility: :public, 
									comments: comments_for(node),
									parent: parent,
									node: node,
									language: @language,
									source: source,
								)
						
						store_definition(parent, path.last.to_sym, definition)
						yield definition
						
						if body = node.body
							with_visibility do
								walk_definitions(body, definition, source, &block)
							end
						end
					when :singleton_class_node
						if name = singleton_name_for(node)
							definition = Singleton.new(name,
										comments: comments_for(node),
										parent: parent,
										node: node,
										language: @language,
										visibility: :public,
										source: source
									)
							
							yield definition
							
							if body = node.body
								walk_definitions(body, definition, source, &block)
							end
						end
					when :def_node
						receiver = receiver_for(node.receiver)
						
						definition = Method.new(node.name,
									visibility: @visibility,
									comments: comments_for(node),
									parent: parent,
									node: node,
									language: @language,
									receiver: receiver,
									source: source,
								)
						
						yield definition
					when :constant_write_node
						definition = Constant.new(node.name,
									comments: comments_for(node),
									parent: parent,
									node: node,
									language: @language,
								)
						
						store_definition(parent, node.name, definition)
						yield definition
					when :call_node
						name = node.name
						
						case name
						when :public, :protected, :private
							# Handle cases like "private def foo" where method definitions are arguments
							if node.arguments
								has_method_definitions = false
								node.arguments.arguments.each do |argument_node|
									if argument_node.type == :def_node
										has_method_definitions = true
										# Process the method definition with the specified visibility
										receiver = receiver_for(argument_node.receiver)
										
										definition = Method.new(argument_node.name,
													visibility: name,
													comments: comments_for(argument_node),
													parent: parent,
													node: argument_node,
													language: @language,
													receiver: receiver,
												)
										
										yield definition
									end
								end
								
								# Only set visibility state if this is NOT an inline method definition
								unless has_method_definitions
									@visibility = name
								end
							else
								# No arguments, so this is a standalone visibility modifier
								@visibility = name
							end
						when :private_constant
							if node.arguments
								constant_names_for(node.arguments.arguments) do |name|
									if definition = lookup_definition(parent, name)
										definition.visibility = :private
									end
								end
							end
						when :attr, :attr_reader, :attr_writer, :attr_accessor
							definition = Attribute.new(attribute_name_for(node),
										comments: comments_for(node),
										parent: parent, language: @language, node: node
									)
							
							yield definition
						when :alias_method
							# Handle alias_method :new_name, :old_name syntax
							if node.arguments && node.arguments.arguments.size >= 2
								new_name_arg = node.arguments.arguments[0]
								old_name_arg = node.arguments.arguments[1]
								
								# Extract symbol names from the arguments
								new_name = symbol_name_for(new_name_arg)
								old_name = symbol_name_for(old_name_arg)
								
								definition = Alias.new(new_name.to_sym, old_name.to_sym,
											comments: comments_for(node),
											parent: parent,
											node: node,
											language: @language,
											visibility: @visibility,
											source: source,
										)
								
								yield definition
							end
						else
							# Check if this call should be treated as a definition
							# either because it has a @name comment, @attribute comment, or a block
							has_name_comment = comments_for(node).any? {|comment| comment.match(NAME_ATTRIBUTE)}
							has_attribute_comment = kind_for(node, comments_for(node))
							has_block = node.block
							
							if has_name_comment || has_attribute_comment || has_block
								definition = Call.new(
											attribute_name_for(node),
											comments: comments_for(node),
											parent: parent, language: @language, node: node
										)
								
								yield definition
								
								# Walk into the block body if it exists
								if node.block
									walk_definitions(node.block, definition, source, &block)
								end
							end
						end
					when :alias_method_node
						# Handle alias new_name old_name syntax
						new_name = node.new_name.unescaped
						old_name = node.old_name.unescaped
						
						definition = Alias.new(new_name.to_sym, old_name.to_sym,
									comments: comments_for(node),
									parent: parent,
									node: node,
									language: @language,
									visibility: @visibility,
									source: source,
								)
						
						yield definition
					when :if_node
						# Walk the 'if' branch (statements):
						if node.statements
							walk_definitions(node.statements, parent, source, &block)
						end
						# Walk the 'else' or 'elsif' branch (subsequent):
						if node.subsequent
							walk_definitions(node.subsequent, parent, source, &block)
						end
					when :unless_node
						# Walk the 'unless' branch (statements):
						if node.statements
							walk_definitions(node.statements, parent, source, &block)
						end
						# Walk the 'else' branch (else_clause):
						if node.else_clause
							walk_definitions(node.else_clause, parent, source, &block)
						end
					else
						if node.respond_to?(:statements)
							walk_definitions(node.statements, parent, source, &block)
						else
							# $stderr.puts "Ignoring #{node.type}"
						end
					end
				end
				
				# Extract segments from the given input file.
				# @parameter source [Source] The source file to parse.
				# @returns [Enumerator[Segment]] An enumerator of segments.
				def segments_for(source, &block)
					result = self.parse_source(source)
					comments = result.comments.reject do |comment|
						comment.location.slice.start_with?("#!/") || 
								comment.location.slice.start_with?("# frozen_string_literal:") ||
								comment.location.slice.start_with?("# Released under the MIT License.") ||
								comment.location.slice.start_with?("# Copyright,")
					end
					
					# Now we iterate over the syntax tree and generate segments:
					walk_segments(result.value, comments, &block)
				end
				
				private
				
				# Extract clean comment text from a node by removing leading # symbols and whitespace.
				# Only returns comments that directly precede the node (i.e., are adjacent to it).
				# @parameter node [Node] The AST node with comments.
				# Extract comments that directly precede a node.
				# @parameter node [untyped] The syntax tree node.
				# @returns [Array[String]] Array of cleaned comment strings.
				def comments_for(node)
					# Find the node's starting line
					node_start_line = node.location.start_line
					
					# Filter comments to only include those that directly precede the node
					# We work backwards from the line before the node to find consecutive comments
					adjacent_comments = [] #: Array[String]
					expected_line = node_start_line - 1
					
					# Process comments in reverse order to work backwards from the node
					node.comments.reverse_each do |comment|
						comment_line = comment.location.start_line
						
						# If this comment is on the expected line, it's adjacent
						if comment_line == expected_line
							adjacent_comments.unshift(comment)
							expected_line = comment_line - 1
						elsif comment_line < expected_line
							# If we hit a comment that's too far back, stop
							break
						end
						# If comment_line > expected_line, skip it (it's not adjacent)
					end
					
					# Clean and return the adjacent comments
					adjacent_comments.map do |comment|
						text = comment.slice
						# Remove leading # and optional whitespace
						text.sub(/\A\#\s?/, "")
					end
				end
				
				# Assign a definition to a parent scope.
				# @parameter parent [Definition?] The parent definition.
				# @parameter definition [Definition] The definition to assign.
				def assign_definition(parent, definition)
					parent_definitions = @definitions[parent] ||= {}
					parent_definitions[definition.name] = definition
				end
				
				# Look up a definition in the parent scope.
				# @parameter parent [Definition?] The parent definition.
				# @parameter name [Symbol] The definition name to look up.
				# @returns [Definition?] The found definition, if any.
				def lookup_definition(parent, name)
					if parent_definitions = @definitions[parent]
						return parent_definitions[name]
					end
				end
				
				# Store a definition in the parent scope.
				# @parameter parent [Definition?] The parent definition.
				# @parameter name [Symbol] The definition name.
				# @parameter definition [Definition] The definition to store.
				def store_definition(parent, name, definition)
					parent_definitions = @definitions[parent] ||= {}
					parent_definitions[name] = definition
				end
				
				# Parse the given source object, can be a string or a Source instance.
				# @parameter source [String | Source] The source to parse.
				def parse_source(source)
					if source.is_a?(Source)
						Prism.parse(source.read, filepath: source.path)
					else
						Prism.parse(source)
					end
				end
				
				def with_visibility(visibility = :public, &block)
					saved_visibility = @visibility
					@visibility = visibility
					yield
						ensure
							@visibility = saved_visibility
				end
				
				NAME_ATTRIBUTE = /\A@name\s+(?<value>.*?)\Z/
				
				def attribute_name_for(node)
					comments_for(node).each do |comment|
						if match = comment.match(NAME_ATTRIBUTE)
							return match[:value].to_sym
						end
					end
					
					if node.arguments && node.arguments.arguments.any?
						argument = node.arguments.arguments.first
						case argument.type
						when :symbol_node
							return argument.unescaped.to_sym
						when :call_node
							return argument.name
						when :block_node
							return node.name
						end
					end
					
					return node.name
				end
				
				def nested_path_for(node, path = [])
					return nil if node.nil?
					
					case node.type
					when :constant_read_node
						path << node.name
					when :constant_path_node
						nested_path_for(node.parent, path)
						path << node.name
					end
					
					return path.empty? ? nil : path
				end
				
				def nested_name_for(node)
					nested_path_for(node)&.join("::")
				end
				
				def symbol_name_for(node)
					case node.type
					when :symbol_node
						node.unescaped
					else
						node.slice
					end
				end
				
				def receiver_for(node)
					return nil unless node
					
					case node.type
					when :self_node
						"self"
					when :constant_read_node
						node.name.to_s
					when :constant_path_node
						nested_name_for(node)
					end
				end
				
				def singleton_name_for(node)
					case node.expression.type
					when :self_node
						"self"
					when :constant_read_node
						nested_name_for(node.expression)
					end
				end
				
				KIND_ATTRIBUTE = /\A
							(@(?<kind>attribute)\s+(?<value>.*?))|
							(@define\s+(?<kind>)\s+(?<value>.*?))
						\Z/x
				
				def kind_for(node, comments = nil)
					comments&.each do |comment|
						if match = comment.match(KIND_ATTRIBUTE)
							return match[:kind].to_sym
						end
					end
					
					return nil
				end
				
				SCOPE_ATTRIBUTE = /\A
							@scope\s+(?<names>.*?)
						\Z/x
				
				def scope_for(comments, parent = nil, &block)
					comments&.each do |comment|
						if match = comment.match(SCOPE_ATTRIBUTE)
							return match[:names].split(/\s+/).map(&:to_sym).inject(nil) do |memo, name|
								scope = Scope.new(name, parent: memo, language: @language)
								yield scope
								scope
							end
						end
					end
					
					return parent
				end
				
				def constant_names_for(child_nodes)
					child_nodes.each do |node|
						if node.type == :symbol_node
							yield node.unescaped.to_sym
						end
					end
				end
				
				def walk_segments(node, comments, &block)
					case node.type
					when :program_node
						walk_segments(node.statements, comments, &block)
					when :statements_node
						statements = node.child_nodes
						current_segment = nil
						
						statements.each_with_index do |statement, statement_index|
							# Find comments that precede this statement and are not inside previous statements
							preceding_comments = []
							last_statement_end_line = statement_index > 0 ? statements[statement_index - 1].location.end_line : 0
							
							comments.each do |comment|
								comment_line = comment.location.start_line
								# Comment must be after the previous statement and before this statement
								if comment_line > last_statement_end_line && comment_line < statement.location.start_line
									preceding_comments << comment
								end
							end
							
							# Remove consumed comments
							comments -= preceding_comments
							
							if preceding_comments.any?
								# Start a new segment with these comments
								yield current_segment if current_segment
								current_segment = Segment.new(
											preceding_comments.map{|comment| comment.location.slice.sub(/^#[\s\t]?/, "")},
											@language,
											statement
										)
							elsif current_segment
								# Extend current segment with this statement
								current_segment.expand(statement)
							else
								# Start a new segment without comments
								current_segment = Segment.new(
											[],
											@language,
											statement
										)
							end
						end
						
						yield current_segment if current_segment
					else
						# One top level segment:
						segment = Segment.new(
									[],
									@language,
									node
								)
						
						yield segment
					end
				end
			end
		end
	end
end
