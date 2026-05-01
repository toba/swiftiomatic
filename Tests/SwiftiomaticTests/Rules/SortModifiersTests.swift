@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct SortModifiersTests: RuleTesting {

  @Test func staticBeforePublic() {
    assertFormatting(
      SortModifiers.self,
      input: """
        class Foo {
          1️⃣static public func bar() {}
        }
        """,
      expected: """
        class Foo {
          public static func bar() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "reorder declaration modifiers to follow canonical order"),
      ]
    )
  }

  @Test func correctOrderUnchanged() {
    assertFormatting(
      SortModifiers.self,
      input: """
        class Foo {
          public static func bar() {}
        }
        """,
      expected: """
        class Foo {
          public static func bar() {}
        }
        """,
      findings: []
    )
  }

  @Test func overrideBeforePublic() {
    assertFormatting(
      SortModifiers.self,
      input: """
        class Foo {
          1️⃣override public func bar() {}
        }
        """,
      expected: """
        class Foo {
          public override func bar() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "reorder declaration modifiers to follow canonical order"),
      ]
    )
  }

  @Test func finalStaticBeforePublic() {
    assertFormatting(
      SortModifiers.self,
      input: """
        class Foo {
          1️⃣final static public var x: Int { 0 }
        }
        """,
      expected: """
        class Foo {
          public static final var x: Int { 0 }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "reorder declaration modifiers to follow canonical order"),
      ]
    )
  }

  @Test func singleModifierUnchanged() {
    assertFormatting(
      SortModifiers.self,
      input: """
        public func bar() {}
        """,
      expected: """
        public func bar() {}
        """,
      findings: []
    )
  }

  @Test func requiredConvenienceInit() {
    assertFormatting(
      SortModifiers.self,
      input: """
        class Foo {
          public required convenience init() {}
        }
        """,
      expected: """
        class Foo {
          public required convenience init() {}
        }
        """,
      findings: []
    )
  }

  @Test func lazyVariable() {
    assertFormatting(
      SortModifiers.self,
      input: """
        class Foo {
          1️⃣lazy private var x = 0
        }
        """,
      expected: """
        class Foo {
          private lazy var x = 0
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "reorder declaration modifiers to follow canonical order"),
      ]
    )
  }

  @Test func weakVariable() {
    assertFormatting(
      SortModifiers.self,
      input: """
        class Foo {
          1️⃣weak private var delegate: Delegate?
        }
        """,
      expected: """
        class Foo {
          private weak var delegate: Delegate?
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "reorder declaration modifiers to follow canonical order"),
      ]
    )
  }

  @Test func overrideOpenFunc() {
    assertFormatting(
      SortModifiers.self,
      input: """
        class Foo {
          open override func bar() {}
        }
        """,
      expected: """
        class Foo {
          open override func bar() {}
        }
        """,
      findings: []
    )
  }
}
