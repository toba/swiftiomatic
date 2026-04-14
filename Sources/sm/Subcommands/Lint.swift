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

extension SwiftiomaticCommand {
  /// Emits style diagnostics for one or more files containing Swift code.
  struct Lint: ParsableCommand {
    nonisolated(unsafe) static var configuration = CommandConfiguration(
      abstract: "Diagnose style issues in Swift source code",
      discussion: "When no files are specified, it expects the source from standard input."
    )

    @OptionGroup()
    var configurationOptions: ConfigurationOptions

    @OptionGroup()
    var lintOptions: LintFormatOptions

    @Flag(
      name: .shortAndLong,
      help: "Treat all findings as errors instead of warnings."
    )
    var strict: Bool = false

    func run() throws {
      let frontend = LintFrontend(
        configurationOptions: configurationOptions,
        lintFormatOptions: lintOptions,
        treatWarningsAsErrors: strict
      )
      frontend.run()

      if frontend.diagnosticsEngine.hasErrors {
        throw ExitCode.failure
      }
    }
  }
}
