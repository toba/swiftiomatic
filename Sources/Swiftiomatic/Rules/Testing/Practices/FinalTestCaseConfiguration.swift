struct FinalTestCaseConfiguration: RuleConfiguration {
    let id = "final_test_case"
    let name = "Final Test Case"
    let summary = "Test cases should be final"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("final class Test: XCTestCase {}"),
              Example("open class Test: XCTestCase {}"),
              Example("public final class Test: QuickSpec {}"),
              Example("class Test: MyTestCase {}"),
              Example(
                "struct Test: MyTestCase {}",
                configuration: ["test_parent_classes": "MyTestCase"],
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("class ↓Test: XCTestCase {}"),
              Example("public class ↓Test: QuickSpec {}"),
              Example(
                "class ↓Test: MyTestCase {}",
                configuration: ["test_parent_classes": "MyTestCase"],
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("class ↓Test: XCTestCase {}"):
                Example("final class Test: XCTestCase {}"),
              Example("internal class ↓Test: XCTestCase {}"):
                Example("internal final class Test: XCTestCase {}"),
            ]
    }
}
