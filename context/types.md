# Setting Up RBS Types and Steep Type Checking for Ruby Gems

This guide covers the process for establishing robust type checking in Ruby gems using RBS and Steep, focusing on automated generation from source documentation and proper validation.

## Core Process

### Documentation-Driven RBS Generation

Generate RBS files from documentation:

```bash
bake decode:rbs:generate lib > sig/example/gem.rbs`
```

At a minimum, add `@parameter`, `@attribute` and `@returns` documentation to all public methods.

#### Parametric Types

Use `@rbs generic` comments to define type parameters for classes and modules:

```ruby
# @rbs generic T
class Container
	# @parameter item [T] The item to store
	def initialize(item)
		@item = item
	end
	
	# @returns [T] The stored item
	def get
		@item
	end
end
```

Use `@rbs` comments for parametric method signatures:

```ruby
# From above:
class Container
	# @rbs () { (T) -> void } -> void
	def each
		yield @item
	end
```

#### Interfaces

Create interfaces in `sig/example/gem/interface.rbs`:

```rbs
module Example
	module Gem
		interface _Interface
		end
	end
end
```

You can use the interface in `@parameter`, `@attribute` and `@returns` types.

### Testing

Run tests using the `steep` gem.

```bash
steep check
```

**Process**: Start with basic generation, then refine based on Steep feedback.

1. Generate initial RBS from documentation
2. Run `steep check lib` to identify issues
3. Fix structural problems (inheritance, missing docs)
4. Iterate until clean validation
