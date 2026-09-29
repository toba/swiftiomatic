import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseInlineAlwaysNotUnderscoreTests: RuleTesting {
    private static let message =
        "replace '@inline(__always)' with '@inline(always)', which guarantees inlining since Swift 6.3"

    @Test func freeFunction() {
        assertFormatting(
            UseInlineAlwaysNotUnderscore.self,
            input: """
                1️⃣@inline(__always)
                func foo() {}
                """,
            expected: """
                @inline(always)
                func foo() {}
                """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func structMember() {
        assertFormatting(
            UseInlineAlwaysNotUnderscore.self,
            input: """
                struct S {
                  1️⃣@inline(__always) func foo() {}
                }
                """,
            expected: """
                struct S {
                  @inline(always) func foo() {}
                }
                """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func enumAndActorMembers() {
        assertFormatting(
            UseInlineAlwaysNotUnderscore.self,
            input: """
                enum E {
                  1️⃣@inline(__always) static func foo() {}
                }
                actor A {
                  2️⃣@inline(__always) func bar() {}
                }
                """,
            expected: """
                enum E {
                  @inline(always) static func foo() {}
                }
                actor A {
                  @inline(always) func bar() {}
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: Self.message), FindingSpec("2️⃣", message: Self.message),
            ]
        )
    }

    @Test func nonOverridableClassMembers() {
        assertFormatting(
            UseInlineAlwaysNotUnderscore.self,
            input: """
                class C {
                  1️⃣@inline(__always) static func a() {}
                  2️⃣@inline(__always) final func b() {}
                  3️⃣@inline(__always) private func c() {}
                  4️⃣@inline(__always) fileprivate func d() {}
                }
                """,
            expected: """
                class C {
                  @inline(always) static func a() {}
                  @inline(always) final func b() {}
                  @inline(always) private func c() {}
                  @inline(always) fileprivate func d() {}
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: Self.message),
                FindingSpec("2️⃣", message: Self.message),
                FindingSpec("3️⃣", message: Self.message),
                FindingSpec("4️⃣", message: Self.message),
            ]
        )
    }

    @Test func finalClassMember() {
        assertFormatting(
            UseInlineAlwaysNotUnderscore.self,
            input: """
                final class C {
                  1️⃣@inline(__always) func a() {}
                }
                """,
            expected: """
                final class C {
                  @inline(always) func a() {}
                }
                """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func accessorInStruct() {
        assertFormatting(
            UseInlineAlwaysNotUnderscore.self,
            input: """
                struct S {
                  var x: Int {
                    1️⃣@inline(__always) get { 0 }
                  }
                }
                """,
            expected: """
                struct S {
                  var x: Int {
                    @inline(always) get { 0 }
                  }
                }
                """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func localFunctionInClassMethod() {
        assertFormatting(
            UseInlineAlwaysNotUnderscore.self,
            input: """
                class C {
                  func a() {
                    1️⃣@inline(__always) func helper() {}
                  }
                }
                """,
            expected: """
                class C {
                  func a() {
                    @inline(always) func helper() {}
                  }
                }
                """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func overridableClassMemberLintsOnly() {
        assertFormatting(
            UseInlineAlwaysNotUnderscore.self,
            input: """
                class C {
                  1️⃣@inline(__always) func a() {}
                  2️⃣@inline(__always) class func b() {}
                  3️⃣@inline(__always) var x: Int { 0 }
                }
                """,
            expected: """
                class C {
                  @inline(__always) func a() {}
                  @inline(__always) class func b() {}
                  @inline(__always) var x: Int { 0 }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: Self.message),
                FindingSpec("2️⃣", message: Self.message),
                FindingSpec("3️⃣", message: Self.message),
            ]
        )
    }

    @Test func overridableClassAccessorLintsOnly() {
        assertFormatting(
            UseInlineAlwaysNotUnderscore.self,
            input: """
                class C {
                  var x: Int {
                    1️⃣@inline(__always) get { 0 }
                  }
                }
                """,
            expected: """
                class C {
                  var x: Int {
                    @inline(__always) get { 0 }
                  }
                }
                """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func alreadyInlineAlways() {
        assertFormatting(
            UseInlineAlwaysNotUnderscore.self,
            input: """
                @inline(always)
                func foo() {}
                """,
            expected: """
                @inline(always)
                func foo() {}
                """,
            findings: []
        )
    }

    @Test func otherInlineArgumentsIgnored() {
        assertFormatting(
            UseInlineAlwaysNotUnderscore.self,
            input: """
                @inline(never)
                func foo() {}
                @inlinable
                func bar() {}
                """,
            expected: """
                @inline(never)
                func foo() {}
                @inlinable
                func bar() {}
                """,
            findings: []
        )
    }

    @Test func lintOnlyByDefault() {
        #expect(UseInlineAlwaysNotUnderscore.defaultValue.lint == .warn)
        #expect(UseInlineAlwaysNotUnderscore.defaultValue.rewrite == false)
    }

    @Test func defaultFormatKeepsUnderscoredSpelling() throws {
        let input = """
            @inline(__always)
            func foo() {}

            """
        let output = try formatWithPipeline(input, configuration: Configuration())
        assertStringsEqualWithDiff(output, input)
    }
}
