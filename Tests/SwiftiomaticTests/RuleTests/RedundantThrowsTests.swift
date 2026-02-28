import Testing
@testable import Swiftiomatic

@Suite struct RedundantThrowsTests {
    @Test func removesThrowsFromXCTestFunction() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                XCTAssertEqual(1, 1)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssertEqual(1, 1)
            }
        }
        """
        let options = FormatOptions(redundantThrows: .testsOnly)
        testFormatting(for: input, output, rule: .redundantThrows, options: options)
    }

    @Test func removesThrowsFromSwiftTestingFunction() {
        let input = """
        import Testing

        @Test func something() throws {
            #expect(1 == 1)
        }
        """
        let output = """
        import Testing

        @Test func something() {
            #expect(1 == 1)
        }
        """
        let options = FormatOptions(redundantThrows: .testsOnly)
        testFormatting(for: input, output, rule: .redundantThrows, options: options)
    }

    @Test func ignoresNonTestFunctionsInTestsOnlyMode() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func helper() throws {
                // This is not a test function, should not be modified
            }

            func testHelper() throws -> Bool {
                // This is not a test function, should not be modified
                false
            }

            func test_something() throws {
                XCTAssertEqual(1, 1)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func helper() throws {
                // This is not a test function, should not be modified
            }

            func testHelper() throws -> Bool {
                // This is not a test function, should not be modified
                false
            }

            func test_something() {
                XCTAssertEqual(1, 1)
            }
        }
        """
        let options = FormatOptions(redundantThrows: .testsOnly)
        testFormatting(
            for: input, output, rule: .redundantThrows, options: options,
            exclude: [.testSuiteAccessControl, .validateTestCases],
        )
    }

    @Test func removesThrowsFromAnyFunctionInAlwaysMode() {
        let input = """
        func foo() throws -> Int {
            return 0
        }

        init() throws -> Int {
            return 0
        }

        subscript(_: String) throws -> Int {
            return 0
        }
        """
        let output = """
        func foo() -> Int {
            return 0
        }

        init() -> Int {
            return 0
        }

        subscript(_: String) -> Int {
            return 0
        }
        """
        let options = FormatOptions(redundantThrows: .always)
        testFormatting(for: input, output, rule: .redundantThrows, options: options)
    }

    @Test func removesTypedThrowsInAlwaysMode() {
        let input = """
        func foo() throws(MyError) -> Int {
            return 0
        }
        """
        let output = """
        func foo() -> Int {
            return 0
        }
        """
        let options = FormatOptions(redundantThrows: .always)
        testFormatting(for: input, output, rule: .redundantThrows, options: options)
    }

    @Test func doesNotModifyOverrideFunctions() {
        let input = """
        class TestCase {
            override func setUpWithError() throws {
                // Setup code that doesn't actually throw
            }
        }
        """
        let options = FormatOptions(redundantThrows: .always)
        testFormatting(for: input, rule: .redundantThrows, options: options)
    }

    @Test func preservesThrowsWhenFunctionContainsTry() {
        let input = """
        func baz() throws -> Int {
            try somethingThatThrows()
            return 0
        }
        """
        let options = FormatOptions(redundantThrows: .always)
        testFormatting(for: input, rule: .redundantThrows, options: options)
    }

    @Test func preservesThrowsWhenFunctionContainsThrowStatement() {
        let input = """
        func foo() throws -> Int {
            guard someCondition else {
                throw MyError.invalidInput
            }

            return 0
        }
        """
        let options = FormatOptions(redundantThrows: .always)
        testFormatting(for: input, rule: .redundantThrows, options: options)
    }

    @Test func removesThrowsWhenOnlyTryExclamationAndTryQuestion() {
        let input = """
        func foo() throws -> Int {
            try! nonThrowingCall()
            try? anotherCall()
            return 0
        }
        """
        let output = """
        func foo() -> Int {
            try! nonThrowingCall()
            try? anotherCall()
            return 0
        }
        """
        let options = FormatOptions(redundantThrows: .always)
        testFormatting(for: input, output, rule: .redundantThrows, options: options)
    }

    // MARK: - Scoping

    @Test func removesThrowsWhenTryInNestedClosure() {
        let input = """
        func foo() throws -> Int {
            let closure = {
                try somethingThatThrows()
            }
            return 0
        }
        """
        let output = """
        func foo() -> Int {
            let closure = {
                try somethingThatThrows()
            }
            return 0
        }
        """
        let options = FormatOptions(redundantThrows: .always)
        testFormatting(for: input, output, rule: .redundantThrows, options: options)
    }

    @Test func preservesThrowsWhenTryInControlFlow() {
        let input = """
        func foo() throws -> Int {
            if someCondition {
                try somethingThatThrows()
            }
            return 0
        }
        """
        let options = FormatOptions(redundantThrows: .always)
        testFormatting(for: input, rule: .redundantThrows, options: options)
    }
}
