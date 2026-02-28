import Testing
@testable import Swiftiomatic

@Suite struct RedundantTypedThrowsTests {
    @Test func removesRedundantNeverTypeThrows() {
        let input = """
        func foo() throws(Never) -> Int {
            0
        }
        """

        let output = """
        func foo() -> Int {
            0
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, output, rule: .redundantTypedThrows, options: options)
    }

    @Test func removesRedundantAnyErrorTypeThrows() {
        let input = """
        func foo() throws(any Error) -> Int {
            throw MyError.foo
        }
        """

        let output = """
        func foo() throws -> Int {
            throw MyError.foo
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, output, rule: .redundantTypedThrows, options: options)
    }

    @Test func dontRemovesNonRedundantErrorTypeThrows() {
        let input = """
        func bar() throws(BarError) -> Foo {
            throw .foo
        }

        func foo() throws(Error) -> Int {
            throw MyError.foo
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, rule: .redundantTypedThrows, options: options)
    }
}
