# Getting Started

This guide explains how to use `decode` for source code analysis.

## Installation

Add the gem to your project:

~~~ bash
$ bundle add decode
~~~

## Indexing

`decode` turns your source code into a kind of database with rich access to definitions, segments and associated comments. Use {ruby Decode::Index} to build an index of your project by loading in source files:

~~~ ruby
require 'decode/index'

index = Decode::Index.new

# Load all Ruby files into the index:
index.update(Dir['**/*.rb'])
~~~

Once you've done this, you can print out all the definitions from your project:

~~~ ruby
index.definitions.each do |name, symbol|
	puts symbol.long_form
end
~~~

## References

References are strings which can be resolved into definitions. The index allows you to efficiently resolve references.

~~~ ruby
# Lookup a specific symbol:
reference = index.languages.parse_reference("ruby Decode::Index#lookup")
definition = index.lookup(reference).first
puts definition.long_form
~~~

## Documentation

The {ruby Decode::Documentation} provides rich access to the comments that preceed a definition. This includes metadata including `@parameter`, `@returns` and other tags.

~~~ ruby
lines = definition.documentation.text
puts lines
~~~

See {ruby Decode::Comment::Node#traverse} for more details about how to consume this data.
