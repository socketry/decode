# Decode

A Ruby code analysis tool and documentation generator.

[![Development Status](https://github.com/socketry/decode/workflows/Test/badge.svg)](https://github.com/socketry/decode/actions?workflow=Test)

## Motivation

As part of my effort to build [better project documentation](https://github.com/socketry/utopia-project), I needed a better code analysis tool. While less featured than some of the more mature alternatives, this library focuses on the needs of documentation generation, including speed, cross-referencing and (eventually) multi-language support.

## Usage

Please see the [project documentation](https://socketry.github.io/decode/) for more details.

  - [Getting Started](https://socketry.github.io/decode/guides/getting-started/index) - This guide explains how to use `decode` for source code analysis.

  - [Code Coverage](https://socketry.github.io/decode/guides/code-coverage/index) - This guide explains how to compute documentation code coverage.

  - [Extract Symbols](https://socketry.github.io/decode/guides/extract-symbols/index) - This example demonstrates how to extract symbols using the index. An instance of <code class="language-ruby">Decode::Index</code> is used for loading symbols from source code files. These symbols are available as a flat list and as a trie structure. You can look up specific symbols using a reference using <code class="language-ruby">Decode::Index\#lookup</code>.

## Releases

Please see the [project releases](https://socketry.github.io/decode/releases/index) for all releases.

### v0.25.0

  - Singleton classes are not relevant for coverage, so they are now ignored by the coverage reporter.

### v0.24.4

  - Add support for `@constant [Type] Description.` tags.
  - Add support for instance variable type inference from `@attribute` tags.
  - Add support for method visibility in RBS output.

### v0.24.0

  - [Introduce support for RBS signature generation](https://socketry.github.io/decode/releases/index#introduce-support-for-rbs-signature-generation)

### v0.23.5

  - Fix handling of `&block` arguments in call nodes.

### v0.23.4

  - Fix handling of definitions nested within `if`/`unless`/`elsif`/`else` blocks.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
