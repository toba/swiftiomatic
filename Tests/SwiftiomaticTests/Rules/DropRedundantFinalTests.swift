@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropRedundantFinalTests: RuleTesting {
    @Test func finalFuncInFinalClass() {
        assertFormatting(
            DropRedundantFinal.self,
            input: """
                final class Foo {
                    1️⃣final func bar() {}
                }
                """,
            expected: """
                final class Foo {
                    func bar() {}
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "remove 'final'; members of a final class are implicitly final"),
            ]
        )
    }

    @Test func finalVarInFinalClass() {
        assertFormatting(
            DropRedundantFinal.self,
            input: """
                final class Foo {
                    1️⃣final var x: Int { 0 }
                }
                """,
            expected: """
                final class Foo {
                    var x: Int { 0 }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "remove 'final'; members of a final class are implicitly final"),
            ]
        )
    }

    @Test func finalSubscriptInFinalClass() {
        assertFormatting(
            DropRedundantFinal.self,
            input: """
                final class Foo {
                    1️⃣final subscript(i: Int) -> Int { i }
                }
                """,
            expected: """
                final class Foo {
                    subscript(i: Int) -> Int { i }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "remove 'final'; members of a final class are implicitly final"),
            ]
        )
    }

    @Test func finalWithAccessModifier() {
        assertFormatting(
            DropRedundantFinal.self,
            input: """
                final class Foo {
                    public 1️⃣final func bar() {}
                }
                """,
            expected: """
                final class Foo {
                    public func bar() {}
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "remove 'final'; members of a final class are implicitly final"),
            ]
        )
    }

    @Test func multipleRedundantFinals() {
        assertFormatting(
            DropRedundantFinal.self,
            input: """
                final class Foo {
                    1️⃣final func bar() {}
                    2️⃣final var x: Int { 0 }
                }
                """,
            expected: """
                final class Foo {
                    func bar() {}
                    var x: Int { 0 }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "remove 'final'; members of a final class are implicitly final"),
                FindingSpec("2️⃣", message: "remove 'final'; members of a final class are implicitly final"),
            ]
        )
    }

    @Test func nonFinalClassNotFlagged() {
        assertFormatting(
            DropRedundantFinal.self,
            input: """
                class Foo {
                    final func bar() {}
                }
                """,
            expected: """
                class Foo {
                    final func bar() {}
                }
                """,
            findings: []
        )
    }

    @Test func membersWithoutFinalNotFlagged() {
        assertFormatting(
            DropRedundantFinal.self,
            input: """
                final class Foo {
                    func bar() {}
                    var x: Int { 0 }
                }
                """,
            expected: """
                final class Foo {
                    func bar() {}
                    var x: Int { 0 }
                }
                """,
            findings: []
        )
    }

    @Test func nestedFinalClassInFinalClassPreserved() {
        // A nested class is a distinct type; outer-class finality doesn't
        // prevent subclassing of nested classes, so `final` is meaningful.
        assertFormatting(
            DropRedundantFinal.self,
            input: """
                final class Outer {
                    final class Inner {}
                }
                """,
            expected: """
                final class Outer {
                    final class Inner {}
                }
                """,
            findings: []
        )
    }

    @Test func finalFuncStrippedAdjacentToNestedFinalClass() {
        assertFormatting(
            DropRedundantFinal.self,
            input: """
                final class Outer {
                    final class Inner {}
                    1️⃣final func bar() {}
                }
                """,
            expected: """
                final class Outer {
                    final class Inner {}
                    func bar() {}
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "remove 'final'; members of a final class are implicitly final"),
            ]
        )
    }

    @Test func structNotFlagged() {
        assertFormatting(
            DropRedundantFinal.self,
            input: """
                struct Foo {
                    func bar() {}
                }
                """,
            expected: """
                struct Foo {
                    func bar() {}
                }
                """,
            findings: []
        )
    }

    @Test func finalInitInFinalClass() {
        assertFormatting(
            DropRedundantFinal.self,
            input: """
                final class Foo {
                    1️⃣final init() {}
                }
                """,
            expected: """
                final class Foo {
                    init() {}
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "remove 'final'; members of a final class are implicitly final"),
            ]
        )
    }

    @Test func preservesComments() {
        assertFormatting(
            DropRedundantFinal.self,
            input: """
                final class Foo {
                    /// A bar.
                    1️⃣final func bar() {}
                }
                """,
            expected: """
                final class Foo {
                    /// A bar.
                    func bar() {}
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "remove 'final'; members of a final class are implicitly final"),
            ]
        )
    }
}
