# Ignore/Disable Options

Swiftiomatic recognizes one directive for suppressing rules and formatting:
`// sm:ignore`. The directive's scope is determined by where you put it.

## Lone-line directive — applies to the rest of the file

A `// sm:ignore` comment on a line by itself disables rules from that point
through the end of the file. Placing it at the top of the file therefore
disables rules for the entire file.

```swift
// sm:ignore
import Zoo
import Arrays

struct Foo {
  func foo() { bar();baz(); }
}
```

Add a comma-separated list of rule names to disable just those rules:

```swift
// sm:ignore NoSemicolons, IndirectEnum
import Zoo
import Arrays

struct Foo {
  func foo() { bar();baz(); }
}
```

The directive can also appear mid-file. Anything after it (to end of file) is
treated as ignored:

```swift
let a = 5

// sm:ignore NoSemicolons
struct Foo {
  func foo() { bar();baz(); }
}
```

## Trailing directive — applies to the line only

A `// sm:ignore` comment as a trailing comment on the same line as a statement
or member disables rules just for that line:

```swift
let x = "some code with trouble" // sm:ignore
var bar = foo+baz // sm:ignore NoSemicolons
```

## Layout vs. source-transforming rules

The directive disables both source-transforming rules (e.g. `NoSemicolons`,
`SortImports`) and the layout/pretty-printer (line breaks, indentation, line
length). When the rule list is omitted, every rule is disabled.

Layout-ignore is applied per node — placing `// sm:ignore` before a
declaration tells the pretty printer to leave that declaration alone. At the
top of a file, layout-ignore covers the whole file.

## Understanding Nodes

`sm` parses Swift into an abstract syntax tree, where each element of the
source is represented by a node. Layout suppression supports these top-level
node kinds:

- `CodeBlockItemSyntax`, which is either:
  - A single expression (e.g. function call, assignment, expression)
  - A scoped block of code & associated statement(s) (e.g. function declaration,
    struct/class/enum declaration, if/guard statements, switch statement, while
    loop). All code nested syntactically inside of the ignored node is also
    ignored by the formatter.
- `MemberBlockItemSyntax`
  - Any member declaration inside of a declaration (e.g. properties and
    functions declared inside of a struct/class/enum). All code nested
    syntactically inside of the ignored node is also ignored by the formatter.
