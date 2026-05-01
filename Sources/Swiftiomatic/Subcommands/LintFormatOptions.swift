// sm:ignore-file: noRetroactiveConformances
// Range/ClosedRange need ExpressibleByArgument for swift-argument-parser; we don't own either type.
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import ArgumentParser

/// Common arguments used by the `lint` and `format` subcommands.
struct LintFormatOptions: ParsableArguments {
    /// A list of "start:end" pairs specifying UTF-8 offsets of the ranges to format.
    ///
    /// If not specified, the whole file will be formatted.
    @Option(
        name: .long,
        help: """
            A "start:end" pair specifying UTF-8 offsets of the range to format. Multiple ranges can be
            formatted by specifying several --offsets arguments.
            """
    )
    var offsets: [Range<Int>] = []

    /// A list of "start:end" pairs specifying 1-based line numbers of the ranges to format.
    ///
    /// If not specified, the whole file will be formatted.
    @Option(
        name: .long,
        help: """
            A "start:end" pair specifying 1-based line numbers of the range to format. Multiple ranges
            can be formatted by specifying several --lines arguments. Line numbers are inclusive.
            """
    )
    var lines: [ClosedRange<Int>] = []

    /// The filename for the source code when reading from standard input, to include in diagnostic
    /// messages.
    ///
    /// If not specified and standard input is used, a dummy filename is used for diagnostic
    /// messages about the source from standard input.
    @Option(
        help: "When using standard input, the filename of the source to include in diagnostics.")
    var assumeFilename: String?

    /// Whether or not to run the formatter/linter recursively.
    ///
    /// If set, we recursively run on all ".swift" files in any provided directories.
    @Flag(
        name: .shortAndLong,
        help: "Recursively run on '.swift' files in any provided directories."
    )
    var recursive = false

    /// Whether unparsable files, due to syntax errors or unrecognized syntax, should be ignored or
    /// treated as containing an error. When ignored, unparsable files are output verbatim in format
    /// mode and no diagnostics are raised in lint mode. When not ignored, unparsable files raise a
    /// diagnostic in both format and lint mode.
    @Flag(
        help: """
            Ignores unparsable files, disabling all diagnostics and formatting for files that contain \
            invalid syntax.
            """
    )
    var ignoreUnparsableFiles = false

    /// Whether or not to run the formatter/linter in parallel.
    @Flag(
        name: .shortAndLong,
        help: "Process files in parallel, simultaneously across multiple cores."
    )
    var parallel = false

    /// Whether colors should be used in diagnostics printed to standard error.
    ///
    /// If nil, color usage will be automatically detected based on whether standard error is
    /// connected to a terminal or not.
    @Flag(
        inversion: .prefixedNo,
        help: """
            Enables or disables color diagnostics when printing to standard error. The default behavior \
            if this flag is omitted is to use colors if standard error is connected to a terminal, and \
            to not use colors otherwise.
            """
    )
    var colorDiagnostics: Bool?

    /// Whether symlinks should be followed.
    @Flag(
        help: """
            Follow symbolic links passed on the command line, or found during directory traversal when \
            using `-r/--recursive`.
            """
    )
    var followSymlinks = false

    @Option(
        name: .customLong("enable-experimental-feature"),
        help: """
            The name of an experimental swift-syntax parser feature that should be enabled by \
            sm. Multiple features can be enabled by specifying this flag multiple times.
            """
    )
    var experimentalFeatures: [String] = []

    /// The list of paths to Swift source files that should be formatted or linted.
    @Argument(help: "Zero or more input filenames. Use `-` for stdin.")
    var paths: [String] = []

    @Flag(help: .hidden) var debugDisablePrettyPrint = false
    @Flag(help: .hidden) var debugDumpTokenStream = false

    mutating func validate() throws {
        if recursive, paths.isEmpty {
            throw ValidationError("'--recursive' is only valid when formatting or linting files")
        }

        if assumeFilename != nil, !(paths.isEmpty || paths == ["-"]) {
            throw ValidationError("'--assume-filename' is only valid when reading from stdin")
        }

        if !offsets.isEmpty, paths.count > 1 {
            throw ValidationError("'--offsets' is only valid when processing a single file")
        }

        if !lines.isEmpty, paths.count > 1 {
            throw ValidationError("'--lines' is only valid when processing a single file")
        }

        if !offsets.isEmpty, !lines.isEmpty {
            throw ValidationError("'--offsets' and '--lines' are mutually exclusive")
        }

        if !paths.isEmpty, !recursive {
            for path in paths {
                var isDir: ObjCBool = false

                if FileManager.default.fileExists(atPath: path, isDirectory: &isDir),
                   isDir.boolValue
                {
                    throw ValidationError(
                        """
                        '\(path)' is a path to a directory, not a Swift source file.
                        Use the '--recursive' option to handle directories.
                        """
                    )
                }
            }
        }
    }
}

/// Parses a `start:end` argument into integer bounds, requiring `start <= end` .
private func parseIntPair(_ argument: String) -> (start: Int, end: Int)? {
    let pair = argument.components(separatedBy: ":")
    guard pair.count == 2, let start = Int(pair[0]), let end = Int(pair[1]), start <= end else {
        return nil
    }
    return (start, end)
}

public extension Range<Int> {
    init?(argument: String) {
        guard let (start, end) = parseIntPair(argument) else { return nil }
        self = start..<end
    }
}

public extension ClosedRange<Int> {
    init?(argument: String) {
        guard let (start, end) = parseIntPair(argument) else { return nil }
        self = start...end
    }
}

extension Range<Int>: @retroactive ExpressibleByArgument {}
extension ClosedRange<Int>: @retroactive ExpressibleByArgument {}
