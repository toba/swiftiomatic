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
import SwiftiomaticKit

extension SwiftiomaticCommand {
  /// Emits style diagnostics for one or more files containing Swift code.
  struct Lint: ParsableCommand {
    static let configuration = CommandConfiguration(
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

    @Flag(
      name: .long,
      help: """
        Disable the on-disk lint cache. By default, lint findings are cached under \
        .build/sm-lint-cache/ keyed by file content hash and configuration fingerprint, so \
        unchanged files skip re-linting on the next run.
        """
    )
    var noCache: Bool = false

    func run() throws {
      let cache: LintCache? =
        (noCache || LintCache.disabledByEnvironment) ? nil : LintCache()

      let frontend = LintFrontend(
        configurationOptions: configurationOptions,
        lintFormatOptions: lintOptions,
        treatWarningsAsErrors: strict,
        cache: cache
      )
      frontend.run()

      if frontend.diagnosticsEngine.hasErrors {
        throw ExitCode.failure
      }
    }
  }
}
