# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "fileutils"

def initialize(...)
	super
	
	require "decode/index"
	require "yaml"
end

# Generate Markdown documentation for LLM consumption.
# @parameter root [String] The root path to index (e.g., 'lib').
# @parameter output_root [String] The root output directory (e.g., 'context').
# @parameter name [String] The subdirectory name for the generated files (e.g., 'interface').
def markdown(root, output_root: "context", name: "interface")
	index = Decode::Index.for(root)
	
	# Construct full output directory path
	output_directory = File.join(output_root, name)
	
	# Track all generated files for index.yaml
	generated_files = []
	
	# Group definitions by container (class/module)
	containers = {}
	
	# First pass: collect all definitions
	index.definitions.each do |qualified_name, definition|
		# Skip non-public definitions
		next unless definition.public?
		
		# If this is a container, register it
		if definition.container?
			containers[qualified_name] ||= {
				definition: definition,
				methods: [],
				aliases: []
			}
		else
			# This is a method/attribute - add to parent container
			if parent = definition.parent
				# Find the containing class/module
				container_definition = parent
				while container_definition && !container_definition.container?
					container_definition = container_definition.parent
				end
				
				if container_definition
					container_name = container_definition.qualified_name
					containers[container_name] ||= {
						definition: container_definition,
						methods: [],
						aliases: []
					}
					if definition.respond_to?(:alias?) && definition.alias?
						containers[container_name][:aliases] << definition
					else
						containers[container_name][:methods] << definition
					end
				end
			end
		end
	end
	
	$stderr.puts "Found #{containers.size} containers to document"
	
	# Generate markdown files for each container
	containers.each do |qualified_name, data|
		container = data[:definition]
		# Preserve original code order as collected by the parser/index:
		methods = data[:methods]
		aliases = data[:aliases]
		
		# Generate file path
		file_path = File.join(output_directory, "#{qualified_name.gsub('::', '/')}.md")
		FileUtils.mkdir_p(File.dirname(file_path))
		
		# Generate markdown content
		content = generate_container_markdown(container, methods, aliases)
		
		File.write(file_path, content)
		generated_files << {
			path: file_path,
			qualified_name: qualified_name,
			kind: container.respond_to?(:container?) && container.container? ? "class/module" : "class/module"
		}
		
		$stderr.puts "Generated: #{file_path}"
	end
	
	$stderr.puts "Generated #{generated_files.size} files in #{output_directory}"
	
	# Generate overview/index file
	overview_path = File.join(output_root, "#{name}.md")
	overview_content = generate_overview(name, containers, index)
	File.write(overview_path, overview_content)
	$stderr.puts "Generated overview: #{overview_path}"
end

private

# Generate markdown content for a container (class/module) and its methods.
# @parameter container [Decode::Definition]
# @parameter methods [Array]
# @parameter aliases [Array[Decode::Language::Ruby::Alias]]
def generate_container_markdown(container, methods, aliases)
	lines = []
	
	# Title
	lines << "# #{container.qualified_name}"
	lines << ""
	
	# Summary from documentation
	if documentation = container.documentation
		if summary = extract_summary(documentation)
			lines << summary
			lines << ""
		end
	end
	
	# Metadata
	kind = case container
	when Decode::Language::Ruby::Class
		"Class"
	when Decode::Language::Ruby::Module
		"Module"
	when Decode::Language::Ruby::Singleton
		"Singleton"
	else
		"Container"
	end
	
	meta_lines = ["- Kind: #{kind}"]
	if container.respond_to?(:super_class) && container.super_class
		meta_lines << "- Superclass: #{container.super_class}"
	end
	if container.respond_to?(:includes) && container.includes.any?
		meta_lines << "- Includes: #{container.includes.join(', ')}"
	end
	if container.respond_to?(:extends) && container.extends.any?
		meta_lines << "- Extends: #{container.extends.join(', ')}"
	end
	if container.respond_to?(:prepends) && container.prepends.any?
		meta_lines << "- Prepends: #{container.prepends.join(', ')}"
	end
	if container.parent
		meta_lines << "- Namespace: #{container.parent.qualified_name}"
	end
	
	if meta_lines.any?
		lines << "## Metadata"
		lines << ""
		lines.concat(meta_lines)
		lines << ""
	end
	
	# Description
	if documentation = container.documentation
		if description = extract_description(documentation)
			lines << "## Overview"
			lines << ""
			lines << description
			lines << ""
		end
	end	# Attributes
	attributes = methods.select{|m| m.is_a?(Decode::Language::Ruby::Attribute) rescue false}
	if attributes.any?
		lines << "## Attributes"
		lines << ""
		attributes.each do |attribute|
			lines.concat(generate_method_section(attribute))
		end
	end
	
	# Methods
	non_attributes = methods.reject{|m| m.is_a?(Decode::Language::Ruby::Attribute) rescue false}
	if non_attributes.any?
		lines << "## Methods"
		lines << ""
		non_attributes.each do |method|
			lines.concat(generate_method_section(method, aliases))
		end
	end
	
	lines.join("\n")
end

# Generate markdown for a single method.
# Also annotates any alias names that refer to this method within the same container.
def generate_method_section(method, aliases = [])
	lines = []
	
	# Method heading
	lines << "### `#{method.nested_name}`"
	lines << ""
	
	# Also known as (aliases pointing to this method)
	if aliases && !aliases.empty?
		alias_names = aliases.select{|a| a.old_name == method.name}.map(&:name)
		if alias_names.any?
			lines << "_Also known as:_ #{alias_names.map{|n| "`#{n}`"}.join(", ")}"
			lines << ""
		end
	end
	
	# Summary
	if documentation = method.documentation
		if summary = extract_summary(documentation)
			lines << summary
			lines << ""
		end
	end
	
	# Signature
	if signature = method.long_form
		lines << "**Signature:**"
		lines << "```ruby"
		lines << signature
		lines << "```"
		lines << ""
	end
	
	# Parameters
	if documentation = method.documentation
		parameters = documentation.filter(Decode::Comment::Parameter).to_a
		if parameters.any?
			lines << "**Parameters:**"
			parameters.each do |parameter|
				parameter_text = "- `#{parameter.name}` `#{parameter.type}`"
				if description = parameter.text&.join(" ")
					parameter_text << " — #{description}"
				end
				lines << parameter_text
			end
			lines << ""
		end
		
		# Returns
		returns = documentation.filter(Decode::Comment::Returns).to_a
		if returns.any?
			lines << "**Returns:**"
			returns.each do |return_tag|
				return_text = "- `#{return_tag.type}`"
				if description = return_tag.text&.join(" ")
					return_text << " — #{description}"
				end
				lines << return_text
			end
			lines << ""
		end
		
		# Yields
		yields_tags = documentation.filter(Decode::Comment::Yields).to_a
		if yields_tags.any?
			lines << "**Yields:**"
			yields_tags.each do |yields_tag|
				yield_text = "- `#{yields_tag.block}`"
				if description = yields_tag.text&.join(" ")
					yield_text << " — #{description}"
				end
				lines << yield_text
			end
			lines << ""
		end
		
		# Examples
		examples = documentation.filter(Decode::Comment::Example).to_a
		if examples.any?
			examples.each do |example|
				title = example.title || "Example"
				lines << "**#{title}:**"
				lines << "```ruby"
				lines << example.code if example.code
				lines << "```"
				lines << ""
			end
		end
		
		# Description (longer text after summary)
		if description = extract_description(documentation)
			lines << "**Details:**"
			lines << ""
			lines << description
			lines << ""
		end
	end
	
	lines
end

# Extract summary (first paragraph) from documentation.
def extract_summary(documentation)
	return nil unless documentation.text
	
	lines = documentation.text
	summary_lines = []
	
	lines.each do |line|
		line_str = line.to_s.strip
		break if line_str.empty? && summary_lines.any?
		summary_lines << line_str unless line_str.empty?
	end
	
	return nil if summary_lines.empty?
	summary_lines.join(" ")
end

# Extract description (everything after summary) from documentation.
def extract_description(documentation)
	return nil unless documentation.text
	
	lines = documentation.text
	description_lines = []
	found_gap = false
	
	lines.each do |line|
		line_str = line.to_s
		if line_str.strip.empty?
			found_gap = true if description_lines.any?
		elsif found_gap
			description_lines << line_str
		end
	end
	
	return nil if description_lines.empty?
	description_lines.join("\n")
end

# Generate an overview/index file for the documentation.
def generate_overview(name, containers, index)
	lines = []
	
	lines << "# #{name.capitalize}"
	lines << ""
	lines << "This directory contains documentation for all public classes and modules."
	lines << ""
	
	# Group by top-level namespace
	namespaces = {}
	containers.each do |qualified_name, data|
		parts = qualified_name.split("::")
		top_level = parts.first
		namespaces[top_level] ||= []
		namespaces[top_level] << {name: qualified_name, definition: data[:definition]}
	end
	
	lines << "## Namespaces"
	lines << ""
	
	namespaces.keys.sort.each do |namespace|
		items = namespaces[namespace].sort_by{|item| item[:name]}
		
		lines << "### #{namespace}"
		lines << ""
		
		items.each do |item|
			definition = item[:definition]
			relative_path = "#{name}/#{item[:name].gsub('::', '/')}.md"
			
			if documentation = definition.documentation
				if summary = extract_summary(documentation)
					lines << "- [#{item[:name]}](#{relative_path}) - #{summary}"
					next
				end
			end
			
			lines << "- [#{item[:name]}](#{relative_path})"
		end
		
		lines << ""
	end
	
	lines.join("\n")
end
