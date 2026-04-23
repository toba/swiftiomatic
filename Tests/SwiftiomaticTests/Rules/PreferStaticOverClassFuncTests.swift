@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferStaticOverClassFuncTests: RuleTesting {
    @Test func classFuncInFinalClass() {
        assertFormatting(
            PreferStaticOverClassFunc.self,
            input: """
                final class Foo {
                    1️⃣class func bar() {}
                }
                """,
            expected: """
                final class Foo {
                    static func bar() {}
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "use 'static' instead of 'class'; this class is final"),
            ]
        )
    }

    @Test func classVarInFinalClass() {
        assertFormatting(
            PreferStaticOverClassFunc.self,
            input: """
                final class Foo {
                    1️⃣class var shared: Foo { Foo() }
                }
                """,
            expected: """
                final class Foo {
                    static var shared: Foo { Foo() }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "use 'static' instead of 'class'; this class is final"),
            ]
        )
    }

    @Test func classSubscriptInFinalClass() {
        assertFormatting(
            PreferStaticOverClassFunc.self,
            input: """
                final class Foo {
                    1️⃣class subscript(i: Int) -> Int { i }
                }
                """,
            expected: """
                final class Foo {
                    static subscript(i: Int) -> Int { i }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "use 'static' instead of 'class'; this class is final"),
            ]
        )
    }

    @Test func nonFinalClassNotFlagged() {
        assertFormatting(
            PreferStaticOverClassFunc.self,
            input: """
                class Foo {
                    class func bar() {}
                }
                """,
            expected: """
                class Foo {
                    class func bar() {}
                }
                """,
            findings: []
        )
    }

    @Test func staticAlreadyUsedNotFlagged() {
        assertFormatting(
            PreferStaticOverClassFunc.self,
            input: """
                final class Foo {
                    static func bar() {}
                }
                """,
            expected: """
                final class Foo {
                    static func bar() {}
                }
                """,
            findings: []
        )
    }

    @Test func multipleClassMembers() {
        assertFormatting(
            PreferStaticOverClassFunc.self,
            input: """
                final class Foo {
                    1️⃣class func bar() {}
                    2️⃣class var x: Int { 0 }
                }
                """,
            expected: """
                final class Foo {
                    static func bar() {}
                    static var x: Int { 0 }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "use 'static' instead of 'class'; this class is final"),
                FindingSpec("2️⃣", message: "use 'static' instead of 'class'; this class is final"),
            ]
        )
    }

    @Test func classFuncWithAccessModifier() {
        assertFormatting(
            PreferStaticOverClassFunc.self,
            input: """
                final class Foo {
                    public 1️⃣class func bar() {}
                }
                """,
            expected: """
                final class Foo {
                    public static func bar() {}
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "use 'static' instead of 'class'; this class is final"),
            ]
        )
    }

    @Test func preservesComments() {
        assertFormatting(
            PreferStaticOverClassFunc.self,
            input: """
                final class Foo {
                    /// A bar.
                    1️⃣class func bar() {}
                }
                """,
            expected: """
                final class Foo {
                    /// A bar.
                    static func bar() {}
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "use 'static' instead of 'class'; this class is final"),
            ]
        )
    }

    @Test func structNotFlagged() {
        assertFormatting(
            PreferStaticOverClassFunc.self,
            input: """
                struct Foo {
                    static func bar() {}
                }
                """,
            expected: """
                struct Foo {
                    static func bar() {}
                }
                """,
            findings: []
        )
    }
}
