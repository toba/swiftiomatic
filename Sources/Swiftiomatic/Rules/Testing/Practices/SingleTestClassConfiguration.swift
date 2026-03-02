struct SingleTestClassConfiguration: RuleConfiguration {
    let id = "single_test_class"
    let name = "Single Test Class"
    let summary = "Test files should contain a single QuickSpec or XCTestCase class."
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("class FooTests {  }"),
              Example("class FooTests: QuickSpec {  }"),
              Example("class FooTests: XCTestCase {  }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓class FooTests: QuickSpec {  }
                ↓class BarTests: QuickSpec {  }
                """,
              ),
              Example(
                """
                ↓class FooTests: QuickSpec {  }
                ↓class BarTests: QuickSpec {  }
                ↓class TotoTests: QuickSpec {  }
                """,
              ),
              Example(
                """
                ↓class FooTests: XCTestCase {  }
                ↓class BarTests: XCTestCase {  }
                """,
              ),
              Example(
                """
                ↓class FooTests: XCTestCase {  }
                ↓class BarTests: XCTestCase {  }
                ↓class TotoTests: XCTestCase {  }
                """,
              ),
              Example(
                """
                ↓class FooTests: QuickSpec {  }
                ↓class BarTests: XCTestCase {  }
                """,
              ),
              Example(
                """
                ↓class FooTests: QuickSpec {  }
                ↓class BarTests: XCTestCase {  }
                class TotoTests {  }
                """,
              ),
              Example(
                """
                final ↓class FooTests: QuickSpec {  }
                ↓class BarTests: XCTestCase {  }
                class TotoTests {  }
                """,
              ),
            ]
    }
}
