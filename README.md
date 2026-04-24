# Swiftiomatic

This is a fork of Swift.org's [swift-format](https://github.com/swiftlang/swift-format). *That* or [SwiftFormat](https://github.com/nicklockwood/swiftformat) is what you most likely want to use.

## Command Line Usage

The general invocation syntax for `sm` is as follows:

```sh
Swiftiomatic [SUBCOMMAND] [OPTIONS...] [FILES...]
```

The tool supports a number of subcommands, each of which has its own options
and are described below. Descriptions of the subcommands that are available
can also be obtained by running `Swiftiomatic --help`, and the description of
a specific subcommand can be obtained by using the `--help` flag after the
subcommand name; for example, `Swiftiomatic lint --help`.

### Formatting

```sh
Swiftiomatic [format] [OPTIONS...] [FILES...]
```

The `format` subcommand formats one or more Swift source files (or source code
from standard input if no file paths are given on the command line). Writing
out the `format` subcommand is optional; it is the default behavior if no other
subcommand is given.

This subcommand supports all of the
[common lint and format options](#options-supported-by-formatting-and-linting),
as well as the formatting-only options below:

*   `-i/--in-place`: Overwrites the input files when formatting instead of
    printing the results to standard output. _No backup of the original file is
    made before it is overwritten._

### Linting

```sh
Swiftiomatic lint [OPTIONS...] [FILES...]
```

The `lint` subcommand checks one or more Swift source files (or source code
from standard input if no file paths are given on the command line) for style
violations and prints diagnostics to standard error for any violations that
are detected.

This subcommand supports all of the
[common lint and format options](#options-supported-by-formatting-and-linting),
as well as the linting-only options below:

*   `-s/--strict`: If this option is specified, lint warnings will cause the
    tool to exit with a non-zero exit code (failure). By default, lint warnings
    do not prevent a successful exit; only fatal errors (for example, trying to
    lint a file that does not exist) cause the tool to exit unsuccessfully.

### Options Supported by Formatting and Linting

The following options are supported by both the `format` and `lint`
subcommands:

*   `--assume-filename <path>`: The file path that should be used in
    diagnostics when linting or formatting from standard input. If this option
    is not provided, then `<stdin>` will be used as the filename printed in
    diagnostics.

*   `--color-diagnostics/--no-color-diagnostics`: By default, `sm`
    will print diagnostics in color if standard error is connected to a
    terminal and without color otherwise (for example, if standard error is
    being redirected to a file). These flags can be used to force colors on
    or off respectively, regardless of whether the output is going to a
    terminal.

*   `--configuration <file>`: The path to a JSON file that contains
    [configurable settings](#configuring-the-command-line-tool) for
    `sm`. If omitted, a default configuration is use (which
    can be seen by running `Swiftiomatic dump-configuration`).

*   `--ignore-unparsable-files`: If this option is specified and a source file
    contains syntax errors or can otherwise not be parsed successfully by the
    Swift syntax parser, it will be ignored (no diagnostics will be emitted
    and it will not be formatted). Without this option, an error will be
    emitted for any unparsable files.

*   `-p/--parallel`: Process files in parallel, simultaneously across
    multiple cores.

*   `-r/--recursive`: If specified, then the tool will process `.swift` source
    files in any directories listed on the command line and their descendants.
    Without this flag, it is an error to list a directory on the command line.

### Viewing the Default Configuration

```sh
Swiftiomatic dump-configuration
```

The `dump-configuration` subcommand dumps the default configuration in JSON
format to standard output. This can be used to simplify generating a custom
configuration, by redirecting it to a file and editing it.

### Configuring the Command Line Tool

For any source file being checked or formatted, `sm` looks for a
JSON-formatted file named `.Swiftiomatic` in the same directory. If one is
found, then that file is loaded to determine the tool's configuration. If the
file is not found, then it looks in the parent directory, and so on.

If no configuration file is found, a default configuration is used. The
settings in the default configuration can be viewed by running
`Swiftiomatic dump-configuration`, which will dump it to standard
output.

If the `--configuration <configuration>` option is passed to `sm`,
then that configuration will be used unconditionally and the file system will
not be searched.

See [Documentation/Configuration.md](Documentation/Configuration.md) for a
description of the configuration format and the settings that are available.

#### Viewing the Effective Configuration

The `dump-configuration` subcommand accepts a `--effective` flag. If set, it
dumps the configuration that would be used if `sm` was executed from
the current working directory, and accounts for `.Swiftiomatic` files or
 `--configuration` options as outlined above.

### Miscellaneous

Running `Swiftiomatic -v` or `Swiftiomatic --version` will print version
information about `sm` version and then exit.

## Xcode

### Run Script Build Phase

If you have `sm` [installed via Homebrew](#command-line-usage), you can
integrate it as an Xcode Run Script Build Phase to get warnings and errors
displayed inline in the Issue Navigator and in the source editor.

1. In Xcode, select your project in the navigator, then select your app target.
2. Go to the **Build Phases** tab and click **+** → **New Run Script Phase**.
3. Drag the new phase **above** "Compile Sources" so linting runs first.
4. Paste the following script:

```bash
if command -v sm >/dev/null 2>&1
then
    sm lint --parallel --recursive "${SRCROOT}"
else
    echo "warning: sm not installed — see https://github.com/toba/swiftiomatic#command-line-usage"
fi
```

5. Uncheck **"Based on dependency analysis"** so linting runs on every
   incremental build (not just when inputs change).

To fail the build on any lint finding, add `--strict`:

```bash
sm lint --parallel --recursive --strict "${SRCROOT}"
```

To use a project-specific configuration file:

```bash
sm lint --parallel --recursive --configuration "${SRCROOT}/sm.json" "${SRCROOT}"
```

### SPM Plugins

Three SPM plugins are also available when you add swiftiomatic as a package
dependency:

| Plugin | Type | Usage |
|---|---|---|
| **Lint on Build** | Build tool | Runs automatically on every build |
| **Lint Source Code** | Command | Right-click target in navigator → "Lint Source Code" |
| **Format Source Code** | Command | Right-click target in navigator → "Format Source Code" |

## API Usage

`sm` can be easily integrated into other tools written in Swift.
Instead of invoking the formatter by spawning a subprocess, users can depend on
`sm` as a Swift Package Manager dependency and import the
`SwiftFormat` module, which contains the entry points into the formatter's
diagnostic and correction behavior.

Formatting behavior is provided by the `SwiftFormatter` class and linting
behavior is provided by the `SwiftLinter` class. These APIs can be passed
either a Swift source file `URL` or a `Syntax` node representing a
SwiftSyntax syntax tree. The latter capability is particularly useful for
writing code generators, since it significantly reduces the amount of trivia
that the generator needs to be concerned about adding to the syntax nodes it
creates. Instead, it can pass the in-memory syntax tree to the `SwiftFormat`
API and receive perfectly formatted code as output.

Please see the documentation in the
[`SwiftFormatter`](Sources/SwiftFormat/API/SwiftFormatter.swift) and
[`SwiftLinter`](Sources/SwiftFormat/API/SwiftLinter.swift) classes for more
information about their usage.

### Checking Out the Source Code for Development

The `main` branch is used for development. Pull requests should be created
to merge into the `main` branch; changes that are low-risk and compatible with
the latest release branch may be cherry-picked into that branch after they have
been merged into `main`.

If you are interested in developing `sm`, there is additional
documentation about that [here](Documentation/Development.md).

## Contributing

Contributions to Swift are welcomed and encouraged! Please see the
[Contributing to Swift guide](https://swift.org/contributing/).

Before submitting the pull request, please make sure you have [tested your
 changes](https://github.com/apple/swift/blob/main/docs/ContinuousIntegration.md)
 and that they follow the Swift project [guidelines for contributing
 code](https://swift.org/contributing/#contributing-code).

To be a truly great community, [Swift.org](https://swift.org/) needs to welcome
developers from all walks of life, with different backgrounds, and with a wide
range of experience. A diverse and friendly community will have more great
ideas, more unique perspectives, and produce more great code. We will work
diligently to make the Swift community welcoming to everyone.

To give clarity of what is expected of our members, Swift has adopted the
code of conduct defined by the Contributor Covenant. This document is used
across many open source communities, and we think it articulates our values
well. For more, see the [Code of Conduct](https://swift.org/code-of-conduct/).
