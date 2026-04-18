# generate-swiftiomatic

Build tool that runs code generators to produce the `*+Generated.swift` files.

## What It Does

A thin executable that invokes `RuleCollector` to discover all rules in `Sources/Swiftiomatic/Rules/`, then runs each generator (pipeline, registry, name cache, schema, documentation) to produce source files in `Sources/Swiftiomatic/Core/`.

## Usage

```sh
swift run generate-swiftiomatic
```

Run this after adding, removing, or renaming any rule to keep the generated files in sync.

## Where It Fits

This is a development-only build tool, not shipped to users. It depends on the `Generators` target for all generation logic -- `main.swift` just wires up the collector and generators and triggers the output. The generation logic lives in `Generators` (a library target) rather than here so that `SwiftiomaticTests` can also import it to verify generated output stays consistent with the actual rules.
