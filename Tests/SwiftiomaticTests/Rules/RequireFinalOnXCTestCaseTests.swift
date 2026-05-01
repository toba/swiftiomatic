@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireFinalOnXCTestCaseTests: RuleTesting {

    @Test func nonFinalXCTestCaseTriggers() {
        assertLint(
            RequireFinalOnXCTestCase.self,
            """
            class 1️⃣Test: XCTestCase {}
            public class 2️⃣Test2: QuickSpec {}
            internal class 3️⃣Test3: XCTestCase {}
            """,
            findings: [
                FindingSpec("1️⃣", message: "test cases should be 'final'"),
                FindingSpec("2️⃣", message: "test cases should be 'final'"),
                FindingSpec("3️⃣", message: "test cases should be 'final'"),
            ]
        )
    }

    @Test func nonTriggering() {
        assertLint(
            RequireFinalOnXCTestCase.self,
            """
            final class Test: XCTestCase {}
            open class Test2: XCTestCase {}
            public final class Test3: QuickSpec {}
            class NotATest: SomethingElse {}
            """,
            findings: []
        )
    }
}
