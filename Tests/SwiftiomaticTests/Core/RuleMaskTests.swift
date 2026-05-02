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

  // MARK: - Named lone-line directive: applies from comment to EOF.

  @Test func namedDirectiveExtendsToEOF() {
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

  @Test func multipleNamedDirectivesAccumulate() {
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

  @Test func ignoreIdentifierLikeRuleNames() {
    // Rule list parsing accepts identifier-like tokens (letters, digits, underscores) and
    // stops at the first non-identifier token, treating the rest as a free-form comment.
    let text =
      """
      // sm:ignore ru_le, rule2, snake_case_rule
      let a = 123
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("ru_le", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("rule2", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("snake_case_rule", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("default", at: location(ofLine: 2, in: converter)) == .default)
  }

  // MARK: - Trailing free-form comments after the rule list.

  @Test func trailingCommentWithDashSeparator() {
    let text =
      """
      // sm:ignore:next noLeadingUnderscores - @DebugDescription requires this exact name
      let _foo = 1
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(
      mask.ruleState("noLeadingUnderscores", at: location(ofLine: 2, in: converter)) == .disabled
    )
    // Words from the trailing comment must NOT become rule names.
    #expect(mask.ruleState("DebugDescription", at: location(ofLine: 2, in: converter)) == .default)
    #expect(mask.ruleState("requires", at: location(ofLine: 2, in: converter)) == .default)
    #expect(mask.ruleState("name", at: location(ofLine: 2, in: converter)) == .default)
  }

  @Test func trailingCommentWithoutDashSeparator() {
    let text =
      """
      // sm:ignore:next noLeadingUnderscores macro requires this exact name
      let _foo = 1
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(
      mask.ruleState("noLeadingUnderscores", at: location(ofLine: 2, in: converter)) == .disabled
    )
    // `macro` looks identifier-like but isn't comma-separated from the rule list,
    // so it's treated as part of the trailing comment.
    #expect(mask.ruleState("macro", at: location(ofLine: 2, in: converter)) == .default)
    #expect(mask.ruleState("requires", at: location(ofLine: 2, in: converter)) == .default)
  }

  @Test func trailingCommentWithMultipleRules() {
    let text =
      """
      // sm:ignore:next ruleA, ruleB - because reasons go here
      let x = 1
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("ruleA", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("ruleB", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("because", at: location(ofLine: 2, in: converter)) == .default)
    #expect(mask.ruleState("reasons", at: location(ofLine: 2, in: converter)) == .default)
  }

  @Test func trailingCommentOnTrailingDirective() {
    let text =
      """
      let x = 1 // sm:ignore ruleA - explanation
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("ruleA", at: location(ofLine: 1, in: converter)) == .disabled)
    #expect(mask.ruleState("explanation", at: location(ofLine: 1, in: converter)) == .default)
  }

  @Test func nestedDirectivesEachExtendToEOF() {
    let text =
      """
      // sm:ignore rule1
      struct Foo {
        var bar = 0

        // sm:ignore rule4
        var baz = 0

        var barzle = 0
      }
      let after = 0
      """

    let (mask, converter) = createMask(sourceText: text)

    // rule1 disabled from line 1 onward.
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, column: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 6, column: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 10, in: converter)) == .disabled)

    // rule4 disabled only from its directive (line 5) onward.
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

  // MARK: - Trailing directive on any line of a multi-line statement.

  @Test func trailingIgnoreOnFirstLineOfMultiLineStatement() {
    let text =
      """
      let a = 0
      if !items.contains(p) { // sm:ignore rule1
        items.append(p)
      }
      let z = 0
      """

    let (mask, converter) = createMask(sourceText: text)

    // Diagnosed position is on line 2 (the IfStmt).
    #expect(mask.ruleState("rule1", at: location(ofLine: 2, in: converter)) == .disabled)
    // Range covers the whole if (lines 2-4).
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 4, in: converter)) == .disabled)
    // Outside the statement: default.
    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 5, in: converter)) == .default)
  }

  @Test func trailingIgnoreOnLastLineOfMultiLineStatement() {
    let text =
      """
      let a = 0
      if !items.contains(p) {
        items.append(p)
      } // sm:ignore rule1
      let z = 0
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 2, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 4, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 5, in: converter)) == .default)
  }

  @Test func trailingIgnoreOnMemberDoesNotLeakToSiblings() {
    // Regression guard: a trailing directive on one struct member must not extend to other
    // members of the same struct (i.e., must not leak up to the enclosing type's range).
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

  // MARK: - Bare directive: extends to end of file.

  @Test func bareDirectiveExtendsToEOF() {
    let text =
      """
      let a = 123
      // sm:ignore
      let b = 456
      let c = 789
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("anyRule", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("anyRule", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("anyRule", at: location(ofLine: 4, in: converter)) == .disabled)
  }

  @Test func bareDirectiveAtTopOfFileIgnoresEverything() {
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

  @Test func bareDirectiveNestedExtendsToEOFFromItsPosition() {
    let text =
      """
      let a = 5
      let b = 4

      class Foo {
        // sm:ignore
        let member1 = 0
        func foo() {
          baz()
        }
      }

      struct Baz {
      }
      """

    let (mask, converter) = createMask(sourceText: text)

    // anyRule default before the nested bare directive.
    #expect(mask.ruleState("anyRule", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("anyRule", at: location(ofLine: 4, in: converter)) == .default)

    // anyRule disabled at and after the directive (line 5 onward).
    #expect(mask.ruleState("anyRule", at: location(ofLine: 6, column: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("anyRule", at: location(ofLine: 12, in: converter)) == .disabled)
  }

  // MARK: - `:next` directive: applies only to the next statement.

  @Test func nextDirectiveAppliesOnlyToNextStatement() {
    let text =
      """
      let a = 123
      // sm:ignore:next rule1
      let b = 456
      let c = 789
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 4, in: converter)) == .default)
  }

  @Test func bareNextDirectiveAppliesOnlyToNextStatement() {
    let text =
      """
      let a = 123
      // sm:ignore:next
      let b = 456
      let c = 789
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("anyRule", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("anyRule", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("anyRule", at: location(ofLine: 4, in: converter)) == .default)
  }

  @Test func nextDirectiveAppliesToWholeMultiLineStatement() {
    let text =
      """
      let a = 0
      // sm:ignore:next rule1
      if !items.contains(p) {
        items.append(p)
      }
      let z = 0
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 4, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 5, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 6, in: converter)) == .default)
  }

  @Test func nextDirectiveOnMember() {
    let text =
      """
      struct Foo {
        // sm:ignore:next rule1
        var bar = 0
        var baz = 0
      }
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 3, column: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 4, column: 3, in: converter)) == .default)
  }

  // MARK: - Top-of-file named directive: file-level scope.

  @Test func namedDirectiveAtTopOfFileIsFileScoped() {
    let text =
      """
      // sm:ignore rule1, rule2
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
      #expect(mask.ruleState("rule3", at: location(ofLine: i, in: converter)) == .default)
    }
  }
}
