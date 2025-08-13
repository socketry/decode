# Releases

## v0.25.0

  - Singleton classes are not relevant for coverage, so they are now ignored by the coverage reporter.

## v0.24.4

  - Add support for `@constant [Type] Description.` tags.
  - Add support for instance variable type inference from `@attribute` tags.
  - Add support for method visibility in RBS output.

## v0.24.0

### Introduce support for RBS signature generation

Decode now supports generating RBS type signatures from Ruby source code, making it easier to add type annotations to existing Ruby projects. The RBS generator analyzes your Ruby code and documentation to produce type signatures that can be used with tools like Steep, TypeProf, and other RBS-compatible type checkers.

To generate RBS signatures for your Ruby code, use the provided bake task:

``` bash
-- Generate RBS signatures for the current directory
$ bundle exec bake decode:rbs:generate .

-- Generate RBS signatures for a specific directory
$ bundle exec bake decode:rbs:generate lib/
```

The generator will output RBS declarations to stdout, which you can redirect to a file:

``` bash
-- Save RBS signatures to a file
$ bundle exec bake decode:rbs:generate lib/ > sig/generated.rbs
```

The RBS generator produces type signatures for:

  - **Classes and modules** with their inheritance relationships.
  - **Method signatures** with parameter and return types, or explicitly provide `@rbs` method signatures.
  - **Generic type parameters** from `@rbs generic` documentation tags.
  - **Documentation comments** as RBS comments.

## v0.23.5

  - Fix handling of `&block` arguments in call nodes.

## v0.23.4

  - Fix handling of definitions nested within `if`/`unless`/`elsif`/`else` blocks.
