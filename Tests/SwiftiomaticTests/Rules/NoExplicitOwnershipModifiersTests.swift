@testable import SwiftiomaticKit
package import SwiftiomaticTestSupport
package import Testing

@Suite
struct NoExplicitOwnershipModifiersTests: RuleTesting {

  @Test func removesOwnershipFromFunc() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        1️⃣consuming func move() -> Self {}
        """,
      expected: """
        func move() -> Self {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'consuming' ownership modifier"),
      ]
    )
  }

  @Test func removesBorrowingFromFunc() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        1️⃣borrowing func copy() -> Self {}
        """,
      expected: """
        func copy() -> Self {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'borrowing' ownership modifier"),
      ]
    )
  }

  @Test func removesOwnershipFromParameterType() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        func foo(_ bar: 1️⃣consuming Bar) {}
        """,
      expected: """
        func foo(_ bar: Bar) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'consuming' ownership modifier"),
      ]
    )
  }

  @Test func removesBorrowingFromParameterType() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        func foo(_ bar: 1️⃣borrowing Bar) {}
        """,
      expected: """
        func foo(_ bar: Bar) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'borrowing' ownership modifier"),
      ]
    )
  }

  @Test func removesFromClosureParameter() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        foos.map { (foo: 1️⃣consuming Foo) in
          foo.bar
        }
        """,
      expected: """
        foos.map { (foo: Foo) in
          foo.bar
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'consuming' ownership modifier"),
      ]
    )
  }

  @Test func removesFromFunctionType() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        let f: (1️⃣consuming Foo) -> Bar
        """,
      expected: """
        let f: (Foo) -> Bar
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'consuming' ownership modifier"),
      ]
    )
  }

  @Test func multipleParametersWithOwnership() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        func foo(_ a: 1️⃣consuming Foo, _ b: 2️⃣borrowing Bar) {}
        """,
      expected: """
        func foo(_ a: Foo, _ b: Bar) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'consuming' ownership modifier"),
        FindingSpec("2️⃣", message: "remove explicit 'borrowing' ownership modifier"),
      ]
    )
  }

  @Test func noOwnershipModifiersUnchanged() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        func foo(_ bar: Bar) {}
        """,
      expected: """
        func foo(_ bar: Bar) {}
        """,
      findings: []
    )
  }

  @Test func preservesOtherModifiers() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        public 1️⃣consuming func move() -> Self {}
        """,
      expected: """
        public func move() -> Self {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'consuming' ownership modifier"),
      ]
    )
  }

  // MARK: - Noncopyable and nonescapable code keeps its modifiers

  @Test func keepsModifierOnNoncopyableParameterType() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        struct Buffer: ~Copyable {}
        func take(_ buffer: consuming Buffer) {}
        func peek(_ buffer: borrowing Buffer) {}
        """,
      expected: """
        struct Buffer: ~Copyable {}
        func take(_ buffer: consuming Buffer) {}
        func peek(_ buffer: borrowing Buffer) {}
        """,
      findings: []
    )
  }

  @Test func keepsModifierOnNonescapableParameterType() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        struct View: ~Escapable {}
        func read(_ view: borrowing View) {}
        """,
      expected: """
        struct View: ~Escapable {}
        func read(_ view: borrowing View) {}
        """,
      findings: []
    )
  }

  @Test func keepsModifierOnNoncopyableGenericParameter() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        func take<T: ~Copyable>(_ value: consuming T) {}
        func peek<T>(_ value: borrowing T) where T: ~Copyable {}
        """,
      expected: """
        func take<T: ~Copyable>(_ value: consuming T) {}
        func peek<T>(_ value: borrowing T) where T: ~Copyable {}
        """,
      findings: []
    )
  }

  @Test func keepsModifierOnNoncopyableTypeGenericParameter() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        struct Box<Element: ~Copyable>: ~Copyable {
          func store(_ element: consuming Element) {}
        }
        """,
      expected: """
        struct Box<Element: ~Copyable>: ~Copyable {
          func store(_ element: consuming Element) {}
        }
        """,
      findings: []
    )
  }

  @Test func keepsModifierOnSomeNoncopyable() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        func take(_ value: consuming some P & ~Copyable) {}
        """,
      expected: """
        func take(_ value: consuming some P & ~Copyable) {}
        """,
      findings: []
    )
  }

  @Test func keepsModifierOnSpanFamilyType() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        func parse(_ bytes: borrowing RawSpan) {}
        func fill(_ output: consuming OutputSpan<UInt8>) {}
        """,
      expected: """
        func parse(_ bytes: borrowing RawSpan) {}
        func fill(_ output: consuming OutputSpan<UInt8>) {}
        """,
      findings: []
    )
  }

  @Test func keepsMethodModifierInNoncopyableType() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        struct FileHandle: ~Copyable {
          consuming func close() {}
        }
        extension FileHandle {
          borrowing func size() -> Int { 0 }
        }
        protocol Resource: ~Copyable {
          consuming func release()
        }
        """,
      expected: """
        struct FileHandle: ~Copyable {
          consuming func close() {}
        }
        extension FileHandle {
          borrowing func size() -> Int { 0 }
        }
        protocol Resource: ~Copyable {
          consuming func release()
        }
        """,
      findings: []
    )
  }

  @Test func stillRemovesModifierOnCopyableTypeNextToNoncopyable() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        struct Buffer: ~Copyable {}
        func take(_ buffer: consuming Buffer, _ name: 1️⃣consuming String) {}
        func other<T>(_ value: 2️⃣borrowing T) {}
        """,
      expected: """
        struct Buffer: ~Copyable {}
        func take(_ buffer: consuming Buffer, _ name: String) {}
        func other<T>(_ value: T) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'consuming' ownership modifier"),
        FindingSpec("2️⃣", message: "remove explicit 'borrowing' ownership modifier"),
      ]
    )
  }
}
