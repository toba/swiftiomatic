struct PrivateUnitTestConfiguration: RuleConfiguration {
    let id = "private_unit_test"
    let name = "Private Unit Test"
    let summary = "Unit tests marked private are silently skipped"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class FooTest: XCTestCase {
                    func test1() {}
                    internal func test2() {}
                    public func test3() {}
                }
                """,
              ),
              Example(
                """
                internal class FooTest: XCTestCase {
                    func test1() {}
                    internal func test2() {}
                    public func test3() {}
                }
                """,
              ),
              Example(
                """
                public class FooTest: XCTestCase {
                    func test1() {}
                    internal func test2() {}
                    public func test3() {}
                }
                """,
              ),
              Example(
                """
                @objc private class FooTest: XCTestCase {
                    @objc private func test1() {}
                    internal func test2() {}
                    public func test3() {}
                }
                """,
              ),
              // Non-test classes
              Example(
                """
                private class Foo: NSObject {
                    func test1() {}
                    internal func test2() {}
                    public func test3() {}
                }
                """,
              ),
              Example(
                """
                private class Foo {
                    func test1() {}
                    internal func test2() {}
                    public func test3() {}
                }
                """,
              ),
              // Non-test methods
              Example(
                """
                public class FooTest: XCTestCase {
                    private func test1(param: Int) {}
                    private func test2() -> String { "" }
                    private func atest() {}
                    private static func test3() {}
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                private ↓class FooTest: XCTestCase {
                    func test1() {}
                    internal func test2() {}
                    public func test3() {}
                    private func test4() {}
                }
                """,
              ),
              Example(
                """
                class FooTest: XCTestCase {
                    func test1() {}
                    internal func test2() {}
                    public func test3() {}
                    private ↓func test4() {}
                }
                """,
              ),
              Example(
                """
                internal class FooTest: XCTestCase {
                    func test1() {}
                    internal func test2() {}
                    public func test3() {}
                    private ↓func test4() {}
                }
                """,
              ),
              Example(
                """
                public class FooTest: XCTestCase {
                    func test1() {}
                    internal func test2() {}
                    public func test3() {}
                    private ↓func test4() {}
                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example(
                """

                ↓private class Test: XCTestCase {}
                """,
              ): Example(
                """

                class Test: XCTestCase {}
                """,
              ),
              Example(
                """
                class Test: XCTestCase {

                    ↓private func test1() {}
                    private func test2(i: Int) {}
                    @objc private func test3() {}
                    internal func test4() {}
                }
                """,
              ): Example(
                """
                class Test: XCTestCase {

                    func test1() {}
                    private func test2(i: Int) {}
                    @objc private func test3() {}
                    internal func test4() {}
                }
                """,
              ),
            ]
    }
}
