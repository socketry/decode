# Code Coverage

This guide explains how to compute documentation code coverage.

## Using `bake decode:index:coverage`

There is a built in bake command for computing documentation coverage.

~~~ bash
$ bake decode:index:coverage lib
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
~~~

Using this tool can show you areas that might require more attention.
