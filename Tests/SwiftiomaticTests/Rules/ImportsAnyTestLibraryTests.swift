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
@testable import SwiftiomaticKit
import SwiftParser
import Testing

@Suite
struct ImportsAnyTestLibraryTests: RuleTesting {
  struct ImportCase: CustomTestStringConvertible {
    let id: String
    let source: String
    let expected: Context.AnyTestImportState
    var testDescription: String { id }
  }

  /// Every supported test-library module should mark a file as test code, whether imported
  /// directly, via a specific decl import, or from inside a (possibly nested) `#if` conditional.
  private static func importCases(for library: String) -> [ImportCase] {
    [
      ImportCase(
        id: "\(library): direct import",
        source: """
          import Foundation
          import \(library)
          """,
        expected: .importsTestLibrary
      ),
      ImportCase(
        id: "\(library): specific decl import",
        source: """
          import Foundation
          import class \(library).SomeType
          """,
        expected: .importsTestLibrary
      ),
      ImportCase(
        id: "\(library): inside conditional",
        source: """
          import Foundation
          #if SOME_FEATURE_FLAG
            import \(library)
          #endif
          """,
        expected: .importsTestLibrary
      ),
      ImportCase(
        id: "\(library): inside nested conditional",
        source: """
          import Foundation
          #if SOME_FEATURE_FLAG
            import FooBar
            #if os(macOS)
              import \(library)
            #endif
          #endif
          """,
        expected: .importsTestLibrary
      ),
      ImportCase(
        id: "\(library): inside else branch",
        source: """
          import Foundation
          #if SOME_FEATURE_FLAG
            import FooBar
          #else
            import \(library)
          #endif
          """,
        expected: .importsTestLibrary
      ),
    ]
  }

  static let allCases: [ImportCase] =
    [
      ImportCase(
        id: "does not import any test library",
        source: """
          import Foundation
          """,
        expected: .doesNotImportTestLibrary
      )
    ] + supportedTestLibraryModuleNames.flatMap { importCases(for: $0) }

  @Test(arguments: allCases)
  func setImportsAnyTestLibraryReturnsExpectedState(importCase: ImportCase) throws {
    let sourceFile = Parser.parse(source: importCase.source)
    let context = Context(
      configuration: Configuration(),
      operatorTable: .standardOperators,
      findingConsumer: { _ in },
      fileURL: URL(fileURLWithPath: "/tmp/test.swift"),
      sourceFileSyntax: sourceFile
    )
    setImportsAnyTestLibrary(context: context, sourceFile: sourceFile)
    #expect(context.importsAnyTestLibrary == importCase.expected)
  }
}
