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
import SwiftSyntax
import Testing

@Suite
struct RuleMaskTests {
  private func createMask(sourceText: String) -> (RuleMask, SourceLocationConverter) {
    let fileURL = URL(fileURLWithPath: "/tmp/test.swift")
    let syntax = Parser.parse(source: sourceText)
    let converter = SourceLocationConverter(fileName: fileURL.path, tree: syntax)
    let mask = RuleMask(syntaxNode: Syntax(syntax), sourceLocationConverter: converter)
    return (mask, converter)
  }

  private func location(
    ofLine line: Int,
    column: Int = 0,
    in converter: SourceLocationConverter
  ) -> SwiftSyntax.SourceLocation {
    converter.location(for: converter.position(ofLine: line, column: column))
  }

  // MARK: - Lone-line directives extend from their position to end-of-file.

  @Test func loneDirectiveDisablesRulesUntilEOF() {
    let text =
      """
      let a = 123
      // sm:ignore rule1
      let b = 456
      let c = 789
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 4, in: converter)) == .disabled)
  }

  @Test func multipleDirectivesAccumulate() {
    let text =
      """
      let a = 123
      // sm:ignore rule1
      let b = 456
      // sm:ignore rule2
      let c = 789
      let d = "abc"
      """

    let (mask, converter) = createMask(sourceText: text)

    // rule1 disabled from line 3 onward.
    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 5, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 6, in: converter)) == .disabled)

    // rule2 disabled from line 5 onward.
    #expect(mask.ruleState("rule2", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule2", at: location(ofLine: 3, in: converter)) == .default)
    #expect(mask.ruleState("rule2", at: location(ofLine: 5, in: converter)) == .disabled)
    #expect(mask.ruleState("rule2", at: location(ofLine: 6, in: converter)) == .disabled)
  }

  @Test func ignoreComplexRuleNames() {
    let text =
      """
      // sm:ignore ru_le, rule!, ru&le, rule?, rule[], rule(), rule;
      let a = 123
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("ru_le", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("rule!", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("ru&le", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("rule?", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("rule[]", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("rule()", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("rule;", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("default", at: location(ofLine: 2, in: converter)) == .default)
  }

  @Test func nestedDirectiveAlsoExtendsToEOF() {
    let text =
      """
      // sm:ignore rule1
      struct Foo {
        var bar = 0

        // sm:ignore rule4
        var baz = 0

        var bazzle = 0
      }
      let after = 0
      """

    let (mask, converter) = createMask(sourceText: text)

    // rule1 from top-of-file → disabled everywhere after the directive.
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, column: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 6, column: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 10, in: converter)) == .disabled)

    // rule4 nested inside struct → still extends to EOF from that point.
    #expect(mask.ruleState("rule4", at: location(ofLine: 3, column: 3, in: converter)) == .default)
    #expect(mask.ruleState("rule4", at: location(ofLine: 6, column: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule4", at: location(ofLine: 8, column: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule4", at: location(ofLine: 10, in: converter)) == .disabled)
  }

  @Test func nonMatchingDirectivesAreIgnored() {
    // Block comments and malformed forms (e.g. `// sm:ignore:` with no rule list) don't match.
    let text =
      """
      let a = 123
      let c = 789
      /* sm:ignore rule2 */
      let d = 111
      // sm:ignore:
      let b = 456
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 6, in: converter)) == .default)
    #expect(mask.ruleState("rule2", at: location(ofLine: 4, in: converter)) == .default)
  }

  @Test func directiveInsideStringLiteralIsIgnored() {
    let text =
      #"""
      let a = 123
      let b =
        """
        // sm:ignore rule1
        """
      let c = 789
      // sm:ignore rule1
      let d = "abc"
      """#

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 6, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 8, in: converter)) == .disabled)
  }

  // MARK: - Trailing directives are scoped to the line they sit on.

  @Test func trailingIgnoreAllRules() {
    let text =
      """
      let a = 123
      let b = 456 // sm:ignore
      let c = 789
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("anyRule", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, in: converter)) == .default)
  }

  @Test func trailingIgnoreSpecificRules() {
    let text =
      """
      let a = 123
      let b = 456 // sm:ignore rule1, rule2
      let c = 789
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("rule2", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("rule3", at: location(ofLine: 2, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, in: converter)) == .default)
  }

  @Test func trailingIgnoreOnMember() {
    let text =
      """
      struct Foo {
        var bar = 0 // sm:ignore rule1
        var baz = 0
      }
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 2, column: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, column: 3, in: converter)) == .default)
  }

  // MARK: - Top-of-file directive ignores the whole file.

  @Test func namelessTopOfFileIgnoresEverything() {
    let text =
      """
      // sm:ignore
      let a = 5
      let b = 4

      class Foo {
        let member1 = 0
        func foo() {
          baz()
        }
      }

      struct Baz {
      }
      """

    let (mask, converter) = createMask(sourceText: text)

    let lineCount = text.split(separator: "\n").count
    for i in 1..<lineCount {
      #expect(
        mask.ruleState("anyRule", at: location(ofLine: i, in: converter)) == .disabled,
        "expected disabled at line \(i)"
      )
    }
  }

  @Test func topOfFileWithRuleList() {
    let text =
      """
      // sm:ignore rule1, rule2, rule3
      let a = 5
      let b = 4

      class Foo {
        let member1 = 0
      }
      """

    let (mask, converter) = createMask(sourceText: text)

    let lineCount = text.split(separator: "\n").count
    for i in 1..<lineCount {
      #expect(mask.ruleState("rule1", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule2", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule3", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule4", at: location(ofLine: i, in: converter)) == .default)
    }
  }

  @Test func nestedDirectiveExtendsToEOFFromItsPosition() {
    let text =
      """
      let a = 5
      let b = 4

      class Foo {
        // sm:ignore rule1
        let member1 = 0
        func foo() {
          baz()
        }
      }

      struct Baz {
      }
      """

    let (mask, converter) = createMask(sourceText: text)

    // rule1 default before the nested directive.
    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 4, in: converter)) == .default)

    // rule1 disabled at and after the directive (line 5 onward).
    #expect(mask.ruleState("rule1", at: location(ofLine: 6, column: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 12, in: converter)) == .disabled)
  }

  @Test func mixedTopLevelAndMidFileDirectives() {
    let text =
      """
      // sm:ignore rule1, rule2
      let a = 5
      // sm:ignore rule3
      let b = 4

      class Foo {
        // sm:ignore rule3, rule4
        let member1 = 0
      }
      """

    let (mask, converter) = createMask(sourceText: text)

    let lineCount = text.split(separator: "\n").count
    // rule1, rule2 disabled everywhere after the top directive.
    for i in 1..<lineCount {
      #expect(mask.ruleState("rule1", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule2", at: location(ofLine: i, in: converter)) == .disabled)
    }
    // rule3 disabled from its directive (line 3) onward.
    #expect(mask.ruleState("rule3", at: location(ofLine: 2, in: converter)) == .default)
    #expect(mask.ruleState("rule3", at: location(ofLine: 4, in: converter)) == .disabled)
    #expect(mask.ruleState("rule3", at: location(ofLine: 8, column: 3, in: converter)) == .disabled)
    // rule4 disabled from its directive (line 7) onward.
    #expect(mask.ruleState("rule4", at: location(ofLine: 4, in: converter)) == .default)
    #expect(mask.ruleState("rule4", at: location(ofLine: 8, column: 3, in: converter)) == .disabled)
  }

  @Test func multipleSubsetTopOfFileDirectives() {
    let text =
      """
      // sm:ignore rule1
      // sm:ignore rule2
      let a = 5

      class Foo {
        let member1 = 0
      }
      """

    let (mask, converter) = createMask(sourceText: text)

    let lineCount = text.split(separator: "\n").count
    for i in 1..<lineCount {
      #expect(mask.ruleState("rule1", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule2", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule3", at: location(ofLine: i, in: converter)) == .default)
    }
  }

  @Test func subsetAndAllTopOfFileDirectives() {
    let text =
      """
      // sm:ignore rule1
      // sm:ignore
      let a = 5

      class Foo {
        let member1 = 0
      }
      """

    let (mask, converter) = createMask(sourceText: text)

    let lineCount = text.split(separator: "\n").count
    for i in 1..<lineCount {
      #expect(mask.ruleState("rule1", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule2", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule3", at: location(ofLine: i, in: converter)) == .disabled)
    }
  }
}
