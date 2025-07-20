# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

module Decode
	module Comment
		# Represents a node in a comment tree structure.
		class Node
			# Initialize the node.
			# @parameter children [Array(Node | Text)?] The initial children array containing both structured nodes and text content.
			def initialize(children)
				@children = children
			end
			
			# Whether this node has any children nodes.
			# Ignores {Text} instances.
			# @returns [bool]
			def children?
				@children&.any?{|child| child.is_a?(Node)} || false
			end
			
			# Add a child node to this node.
			# @parameter child [Node | Text] The node to add.
			def add(child)
				if children = @children
					children << child
				else
					@children = [child]
				end
				
				return self
			end
			
			# Contains a mix of Node objects (structured comment tags like `@parameter`, `@returns`) and Text objects (plain comment text and tag descriptions).
			# @attribute [Array(Node | Text)?] The children of this node.
			attr :children
			
			# Enumerate all non-text children nodes.
			# @yields {|node| process each node}
			# 	@parameter node [Node] A structured child node (Text nodes are filtered out).
			# @returns [Enumerator(Node)] Returns an enumerator if no block given.
			# @returns [self] Otherwise returns self.
			def each(&block)
				return to_enum unless block_given?
				
				@children&.each do |child|
					yield child if child.is_a?(Node)
				end
				
				return self
			end
			
			# Filter children nodes by class type.
			# @parameter klass [Class] The class to filter by.
			# @yields {|node| process each filtered node}
			# 	@parameter node [Object] A child node that is an instance of klass.
			# @returns [Enumerator(Node)] Returns an enumerator if no block given.
			# @returns [self] Otherwise returns self.
			def filter(klass)
				return to_enum(:filter, klass) unless block_given?
				
				@children&.each do |child|
					yield child if child.is_a?(klass)
				end
				
				return self
			end
			
			# Any lines of text associated with this node.
			# @returns [Array(String)?] The lines of text.
			def text
				if text = self.extract_text
					return text if text.any?
				end
			end
			
			# Traverse the tags from this node using {each}. Invoke `descend.call(child)` to recursively traverse the specified child.
			#
			# @yields {|node, descend| descend.call}
			# 	@parameter node [Node] The current node which is being traversed.
			# 	@parameter descend [Proc] The recursive method for traversing children.
			def traverse(&block)
				descend = ->(node){node.traverse(&block)}
				
				yield(self, descend)
			end
			
			protected
			
			# Extract text lines from Text children of this node.
			# @returns [Array(String)?] Array of text lines, or nil if no children.
			def extract_text
				if children = @children
					children.filter_map do |child|
						child.line if child.is_a?(Text)
					end
				end
			end
		end
	end
end
