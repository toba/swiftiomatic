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

import ArgumentParser
import Foundation

extension SwiftiomaticCommand {
    /// Formats one or more files containing Swift code.
    struct Format: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Format Swift source code",
            discussion: "When no files are specified, it expects the source from standard input."
        )

        /// Whether or not to format the Swift file in-place.
        ///
        /// If specified, the current file is overwritten when formatting.
        @Flag(
            name: .shortAndLong,
            help: "Overwrite the current file when formatting."
        )
        var inPlace = false

        @OptionGroup()
        var configurationOptions: ConfigurationOptions

        @OptionGroup()
        var formatOptions: LintFormatOptions

        func validate() throws {
            // Recursing across a directory tree (either an explicit directory argument or the
            // implicit cwd default when no paths are given) requires `--in-place`; otherwise we'd
            // concatenate every formatted file to stdout, which is almost never what the caller
            // wants.
            if !inPlace {
                if formatOptions.paths.isEmpty, isatty(FileHandle.standardInput.fileDescriptor) != 0
                {
                    throw ValidationError(
                        """
                        '--in-place' is required when formatting a directory tree.

                        Either pass `--in-place` to rewrite files in place, pipe a single file via \
                        stdin, or pass an explicit `.swift` file path.
                        """
                    )
                }

                for path in formatOptions.paths {
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: path, isDirectory: &isDir),
                       isDir.boolValue
                    {
                        throw ValidationError(
                            """
                            '--in-place' is required when formatting a directory ('\(path)').
                            """
                        )
                    }
                }
            }
        }

        func run() throws {
            let frontend = FormatFrontend(
                configurationOptions: configurationOptions,
                lintFormatOptions: formatOptions,
                inPlace: inPlace
            )
            frontend.run()
            if frontend.diagnosticsEngine.hasErrors { throw ExitCode.failure }
        }
    }
}
