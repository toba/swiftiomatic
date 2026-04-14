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
@_spi(Testing) import Swiftiomatic
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

  @Test func singleRule() {
    let text =
      """
      let a = 123
      // swiftiomatic-ignore: rule1
      let b = 456
      let c = 789
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 4, in: converter)) == .default)
  }

  @Test func ignoreTwoRules() {
    let text =
      """
      let a = 123
      // swiftiomatic-ignore: rule1
      let b = 456
      // swiftiomatic-ignore: rule2
      let c = 789
      // swiftiomatic-ignore: rule1, rule2
      let d = "abc"
      let e = "def"
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 5, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 7, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 8, in: converter)) == .default)

    #expect(mask.ruleState("rule2", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule2", at: location(ofLine: 3, in: converter)) == .default)
    #expect(mask.ruleState("rule2", at: location(ofLine: 5, in: converter)) == .disabled)
    #expect(mask.ruleState("rule2", at: location(ofLine: 7, in: converter)) == .disabled)
    #expect(mask.ruleState("rule2", at: location(ofLine: 8, in: converter)) == .default)
  }

  @Test func ignoreComplexRuleNames() {
    let text =
      """
      // swiftiomatic-ignore: ru_le, rule!, ru&le, rule?, rule[], rule(), rule;
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

  @Test func duplicateNested() {
    let text =
      """
      // swiftiomatic-ignore: rule1
      struct Foo {
        var bar = 0

        // swiftiomatic-ignore: rule1
        var baz = 0

        // swiftiomatic-ignore: rule4
        var bazzle = 0

        var barzle = 0
      }
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 3, column: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule4", at: location(ofLine: 3, column: 3, in: converter)) == .default)

    #expect(mask.ruleState("rule1", at: location(ofLine: 6, column: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule4", at: location(ofLine: 6, column: 3, in: converter)) == .default)

    #expect(mask.ruleState("rule1", at: location(ofLine: 9, column: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule4", at: location(ofLine: 9, column: 3, in: converter)) == .disabled)

    #expect(mask.ruleState("rule4", at: location(ofLine: 11, column: 3, in: converter)) == .default)
  }

  @Test func spuriousFlags() {
    let text1 =
      """
      let a = 123
      let b = 456 // swiftiomatic-ignore: rule1
      let c = 789
      /* swiftiomatic-ignore: rule2 */
      let d = 111
      // swiftiomatic-ignore:
      let b = 456
      """

    let (mask1, converter1) = createMask(sourceText: text1)

    #expect(mask1.ruleState("rule1", at: location(ofLine: 1, in: converter1)) == .default)
    #expect(mask1.ruleState("rule1", at: location(ofLine: 2, in: converter1)) == .default)
    #expect(mask1.ruleState("rule1", at: location(ofLine: 3, in: converter1)) == .default)
    #expect(mask1.ruleState("rule1", at: location(ofLine: 5, in: converter1)) == .default)
    #expect(mask1.ruleState("rule1", at: location(ofLine: 7, in: converter1)) == .default)

    let text2 =
      #"""
      let a = 123
      let b =
        """
        // swiftiomatic-ignore: rule1
        """
      let c = 789
      // swiftiomatic-ignore: rule1
      let d = "abc"
      """#

    let (mask2, converter2) = createMask(sourceText: text2)

    #expect(mask2.ruleState("rule1", at: location(ofLine: 1, in: converter2)) == .default)
    #expect(mask2.ruleState("rule1", at: location(ofLine: 6, in: converter2)) == .default)
    #expect(mask2.ruleState("rule1", at: location(ofLine: 8, in: converter2)) == .disabled)
  }

  @Test func namelessDirectiveAffectsAllRules() {
    let text =
      """
      let a = 123
      // swiftiomatic-ignore
      let b = 456
      let c = 789
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("TotallyMadeUpRule", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule1", at: location(ofLine: 4, in: converter)) == .default)
  }

  @Test func directiveWithRulesList() {
    let text =
      """
      let a = 123
      // swiftiomatic-ignore: rule1, rule2   , AnotherRule  , TheBestRule,, ,   , ,
      let b = 456
      let c = 789
      """

    let (mask, converter) = createMask(sourceText: text)

    #expect(mask.ruleState("rule1", at: location(ofLine: 1, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("rule2", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("AnotherRule", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("TheBestRule", at: location(ofLine: 3, in: converter)) == .disabled)
    #expect(mask.ruleState("TotallyMadeUpRule", at: location(ofLine: 3, in: converter)) == .default)
    #expect(mask.ruleState("rule1", at: location(ofLine: 4, in: converter)) == .default)
  }

  @Test func allRulesWholeFileIgnore() {
    let text =
      """
      // This file has important contents.
      // swiftiomatic-ignore-file
      // Everything in this file is ignored.

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
    for i in 0..<lineCount {
      #expect(mask.ruleState("rule1", at: location(ofLine: i, in: converter)) == .disabled)
    }
  }

  @Test func allRulesWholeFileIgnoreNestedInNode() {
    let text =
      """
      // This file has important contents.
      // Everything in this file is ignored.

      let a = 5
      let b = 4

      class Foo {
        // swiftiomatic-ignore-file
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
    for i in 0..<lineCount {
      #expect(mask.ruleState("rule1", at: location(ofLine: i, in: converter)) == .default)
    }
  }

  @Test func singleRuleWholeFileIgnore() {
    let text =
      """
      // This file has important contents.
      // swiftiomatic-ignore-file: rule1
      // Everything in this file is ignored.

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
    for i in 0..<lineCount {
      #expect(mask.ruleState("rule1", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule2", at: location(ofLine: i, in: converter)) == .default)
    }
  }

  @Test func multipleRulesWholeFileIgnore() {
    let text =
      """
      // This file has important contents.
      // swiftiomatic-ignore-file: rule1, rule2, rule3
      // Everything in this file is ignored.

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
    for i in 0..<lineCount {
      #expect(mask.ruleState("rule1", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule2", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule3", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule4", at: location(ofLine: i, in: converter)) == .default)
    }
  }

  @Test func fileAndLineIgnoresMixed() {
    let text =
      """
      // This file has important contents.
      // swiftiomatic-ignore-file: rule1, rule2
      // Everything in this file is ignored.

      let a = 5
      // swiftiomatic-ignore: rule3
      let b = 4

      class Foo {
        // swiftiomatic-ignore: rule3, rule4
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
    for i in 0..<lineCount {
      #expect(mask.ruleState("rule1", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule2", at: location(ofLine: i, in: converter)) == .disabled)
      if i == 7 {
        #expect(mask.ruleState("rule3", at: location(ofLine: i, in: converter)) == .disabled)
        #expect(mask.ruleState("rule4", at: location(ofLine: i, in: converter)) == .default)
      } else if i == 11 {
        #expect(
          mask.ruleState("rule3", at: location(ofLine: i, column: 3, in: converter)) == .disabled
        )
        #expect(
          mask.ruleState("rule4", at: location(ofLine: i, column: 3, in: converter)) == .disabled
        )
      } else {
        #expect(mask.ruleState("rule3", at: location(ofLine: i, in: converter)) == .default)
        #expect(mask.ruleState("rule4", at: location(ofLine: i, in: converter)) == .default)
      }
    }
  }

  @Test func multipleSubsetFileIgnoreDirectives() {
    let text =
      """
      // This file has important contents.
      // swiftiomatic-ignore-file: rule1
      // swiftiomatic-ignore-file: rule2
      // Everything in this file is ignored.

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
    for i in 0..<lineCount {
      #expect(mask.ruleState("rule1", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule2", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule3", at: location(ofLine: i, in: converter)) == .default)
    }
  }

  @Test func subsetAndAllFileIgnoreDirectives() {
    let text =
      """
      // This file has important contents.
      // swiftiomatic-ignore-file: rule1
      // swiftiomatic-ignore-file
      // Everything in this file is ignored.

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
    for i in 0..<lineCount {
      #expect(mask.ruleState("rule1", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule2", at: location(ofLine: i, in: converter)) == .disabled)
      #expect(mask.ruleState("rule3", at: location(ofLine: i, in: converter)) == .disabled)
    }
  }
}
