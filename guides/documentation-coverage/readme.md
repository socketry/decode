# Documentation Coverage

This guide explains how to test and monitor documentation coverage in your Ruby projects using the Decode gem's built-in bake tasks.

## Available Bake Tasks

The Decode gem provides several bake tasks for analyzing your codebase:

- `bake decode:index:coverage` - Check documentation coverage.
- `bake decode:index:symbols` - List all symbols in the codebase.
- `bake decode:index:documentation` - Extract all documentation.

## Checking Documentation Coverage

### Basic Coverage Check

```bash
# Check coverage for the lib directory:
bake decode:index:coverage lib

# Check coverage for a specific directory:
bake decode:index:coverage app/models
```

### Example Output

When you run the coverage command, you'll see output like:

```
Decode
Decode::VERSION
Decode::Languages.all
Decode::Languages#initialize
Decode::Languages#freeze
Decode::Languages#add
Decode::Languages#fetch
Decode::Languages#source_for
Decode::Languages::REFERENCE
Decode::Languages#reference_for
Decode::Source#initialize
... snip ...
135/215 definitions have documentation.
```

Using this tool can show you areas that might require more attention.

### Understanding Coverage Output

The coverage check:
- **Counts only public definitions** (public methods, classes, modules).
- **Reports the ratio** of documented vs total public definitions.
- **Lists missing documentation** by qualified name.
- **Fails with an error** if coverage is incomplete.

### What Counts as "Documented"

A definition is considered documented if it has:
- Any comment preceding it.
- Documentation pragmas (like `@parameter`, `@returns`, `@example`).
- A `@namespace` pragma (for organizational modules).

```ruby
# Represents a user in the system.
class MyClass
end

# @namespace
module OrganizationalModule
	# Contains helper functionality.
end

# Process user data and return formatted results.
# @parameter name [String] The user's name.
# @returns [bool] Success status.
def process(name)
	# Validation logic here:
	return false if name.empty?
	
	# Processing logic:
	true
end

class UndocumentedClass
end
```

## Analyzing Symbols

### List All Symbols

```bash
# See the structure of your codebase
bake decode:index:symbols lib
```

This shows the hierarchical structure of your code:

```
[] -> []
["MyGem"] -> [#<Decode::Language::Ruby::Module:...>]
  MyGem
["MyGem", "User"] -> [#<Decode::Language::Ruby::Class:...>]
    MyGem::User
["MyGem", "User", "initialize"] -> [#<Decode::Language::Ruby::Method:...>]
      MyGem::User#initialize
```

### Extract Documentation

```bash
# Extract all documentation from your codebase
bake decode:index:documentation lib
```

This outputs formatted documentation for all documented definitions:

~~~markdown
## `MyGem::User#initialize`

Initialize a new user with the given email address.

## `MyGem::User#authenticate`

Authenticate the user with a password.
Returns true if authentication is successful.
~~~

## Achieving 100% Coverage

### Document all public APIs

```ruby
# Represents a user management system.
class User
	# @attribute [String] The user's email address.
	attr_reader :email
	
	# Initialize a new user.
	# @parameter email [String] The user's email address.
	def initialize(email)
		# Store the email address:
		@email = email
	end
end
```

### Use @namespace for organizational modules

The best place to add these by default is `version.rb`.

```ruby
# @namespace
module MyGem
	VERSION = "0.1.0"
end
```

### Document edge cases

```ruby
# @private
def internal_helper
	# Add the fields:
	return foo + bar
end
```

### Common Coverage Issues

#### Missing namespace documentation

```ruby
# This module has no documentation and will show as missing coverage:
module MyGem
end

# Solution: Add @namespace pragma:
# @namespace
module MyGem
	# Provides core functionality.
end
```

#### Undocumented methods

Problem: Methods without any comments will show as missing coverage:
```ruby
def process_data
	# Implementation here
end
```

Solution: Add description and pragmas:
```ruby
# Process the input data and return results.
# @parameter data [Hash] Input data to process.
# @returns [Array] Processed results.
def process_data(data)
	# Process the input:
	results = data.map {|item| transform(item)}
	
	# Return processed results:
	results
end
```

#### Missing attr documentation

Problem: Attributes without documentation will show as missing coverage:
```ruby
attr_reader :name
```

Solution: Document with @attribute pragma:
```ruby
# @attribute [String] The user's full name.
attr_reader :name
```

## Integrating into CI/CD

### GitHub Actions Example

```yaml
name: Documentation Coverage

on: [push, pull_request]

jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Check documentation coverage
        run: bake decode:index:coverage lib
```

### Rake Task Integration

Add to your `Rakefile`:

```ruby
require "decode"

desc "Check documentation coverage"
task :doc_coverage do
	system("bake decode:index:coverage lib") || exit(1)
end

task default: [:test, :doc_coverage]
```
