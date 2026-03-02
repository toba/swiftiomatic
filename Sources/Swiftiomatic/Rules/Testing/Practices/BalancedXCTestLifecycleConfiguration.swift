struct BalancedXCTestLifecycleConfiguration: RuleConfiguration {
    let id = "balanced_xctest_lifecycle"
    let name = "Balanced XCTest Life Cycle"
    let summary = "Test classes must implement balanced setUp and tearDown methods"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                #"""
                final class FooTests: XCTestCase {
                    override func setUp() {}
                    override func tearDown() {}
                }
                """#,
              ),
              Example(
                #"""
                final class FooTests: XCTestCase {
                    override func setUpWithError() throws {}
                    override func tearDown() {}
                }
                """#,
              ),
              Example(
                #"""
                final class FooTests: XCTestCase {
                    override func setUp() {}
                    override func tearDownWithError() throws {}
                }
                """#,
              ),
              Example(
                #"""
                final class FooTests: XCTestCase {
                    override func setUpWithError() throws {}
                    override func tearDownWithError() throws {}
                }
                final class BarTests: XCTestCase {
                    override func setUpWithError() throws {}
                    override func tearDownWithError() throws {}
                }
                """#,
              ),
              Example(
                #"""
                struct FooTests {
                    override func setUp() {}
                }
                class BarTests {
                    override func setUpWithError() throws {}
                }
                """#,
              ),
              Example(
                #"""
                final class FooTests: XCTestCase {
                    override func setUpAlLExamples() {}
                }
                """#,
              ),
              Example(
                #"""
                final class FooTests: XCTestCase {
                    class func setUp() {}
                    class func tearDown() {}
                }
                """#,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                #"""
                final class ↓FooTests: XCTestCase {
                    override func setUp() {}
                }
                """#,
              ),
              Example(
                #"""
                final class ↓FooTests: XCTestCase {
                    override func setUpWithError() throws {}
                }
                """#,
              ),
              Example(
                #"""
                final class FooTests: XCTestCase {
                    override func setUp() {}
                    override func tearDownWithError() throws {}
                }
                final class ↓BarTests: XCTestCase {
                    override func setUpWithError() throws {}
                }
                """#,
              ),
              Example(
                #"""
                final class ↓FooTests: XCTestCase {
                    class func tearDown() {}
                }
                """#,
              ),
              Example(
                #"""
                final class ↓FooTests: XCTestCase {
                    override func tearDown() {}
                }
                """#,
              ),
              Example(
                #"""
                final class ↓FooTests: XCTestCase {
                    override func tearDownWithError() throws {}
                }
                """#,
              ),
              Example(
                #"""
                final class FooTests: XCTestCase {
                    override func setUp() {}
                    override func tearDownWithError() throws {}
                }
                final class ↓BarTests: XCTestCase {
                    override func tearDownWithError() throws {}
                }
                """#,
              ),
            ]
    }
    let rationale: String? = """
      The `setUp` method of `XCTestCase` can be used to set up variables and resources before \
      each test is run (or with the `class` variant, before all tests are run).

      This rule verifies that every class with an implementation of a `setUp` method also has \
      a `tearDown` method (and vice versa).

      The `tearDown` method should be used to cleanup or reset any resources that could \
      otherwise have any effects on subsequent tests, and to free up any instance variables.
      """
}
