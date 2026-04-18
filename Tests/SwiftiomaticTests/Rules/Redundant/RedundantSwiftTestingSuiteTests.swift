@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantSwiftTestingSuiteTests: RuleTesting {
  @Test func removesSuiteWithNoArguments() {
    assertFormatting(
      RedundantSwiftTestingSuite.self,
      input: """
        import Testing

        1️⃣@Suite
        struct MyFeatureTests {
            @Test func myFeature() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        struct MyFeatureTests {
            @Test func myFeature() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@Suite' attribute; it is inferred by Swift Testing"),
      ]
    )
  }

  @Test func removesSuiteWithEmptyParentheses() {
    assertFormatting(
      RedundantSwiftTestingSuite.self,
      input: """
        import Testing

        1️⃣@Suite()
        struct OtherTests {
            @Test func otherFeature() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        struct OtherTests {
            @Test func otherFeature() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@Suite' attribute; it is inferred by Swift Testing"),
      ]
    )
  }

  @Test func keepsSuiteWithArguments() {
    assertFormatting(
      RedundantSwiftTestingSuite.self,
      input: """
        import Testing

        @Suite(.serialized)
        struct SerializedTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        @Suite(.serialized)
        struct SerializedTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """,
      findings: []
    )
  }

  @Test func keepsSuiteWithDisplayName() {
    assertFormatting(
      RedundantSwiftTestingSuite.self,
      input: """
        import Testing

        @Suite("My Test Suite")
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        @Suite("My Test Suite")
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """,
      findings: []
    )
  }

  @Test func removesMultipleRedundantSuites() {
    assertFormatting(
      RedundantSwiftTestingSuite.self,
      input: """
        import Testing

        1️⃣@Suite
        struct FirstTests {
            @Test func first() {
                #expect(true)
            }
        }

        2️⃣@Suite()
        struct SecondTests {
            @Test func second() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        struct FirstTests {
            @Test func first() {
                #expect(true)
            }
        }

        struct SecondTests {
            @Test func second() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@Suite' attribute; it is inferred by Swift Testing"),
        FindingSpec("2️⃣", message: "remove redundant '@Suite' attribute; it is inferred by Swift Testing"),
      ]
    )
  }

  @Test func noRemovalWithoutTestingImport() {
    assertFormatting(
      RedundantSwiftTestingSuite.self,
      input: """
        import XCTest

        @Suite
        struct MyTests {
            func test() {
                XCTAssertTrue(true)
            }
        }
        """,
      expected: """
        import XCTest

        @Suite
        struct MyTests {
            func test() {
                XCTAssertTrue(true)
            }
        }
        """,
      findings: []
    )
  }

  @Test func removesSuiteOnSameLineAsDeclaration() {
    assertFormatting(
      RedundantSwiftTestingSuite.self,
      input: """
        import Testing

        1️⃣@Suite struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@Suite' attribute; it is inferred by Swift Testing"),
      ]
    )
  }

  @Test func removesSuiteWithOtherAttributesBefore() {
    assertFormatting(
      RedundantSwiftTestingSuite.self,
      input: """
        import Testing

        1️⃣@Suite
        @MainActor
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        @MainActor
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@Suite' attribute; it is inferred by Swift Testing"),
      ]
    )
  }

  @Test func removesSuiteWithOtherAttributesAfter() {
    assertFormatting(
      RedundantSwiftTestingSuite.self,
      input: """
        import Testing

        @MainActor
        1️⃣@Suite
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        @MainActor
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@Suite' attribute; it is inferred by Swift Testing"),
      ]
    )
  }

  @Test func keepsSuiteWithMultipleArguments() {
    assertFormatting(
      RedundantSwiftTestingSuite.self,
      input: """
        import Testing

        @Suite("Display Name", .serialized)
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        @Suite("Display Name", .serialized)
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """,
      findings: []
    )
  }

  @Test func removesSuiteWithDocComment() {
    assertFormatting(
      RedundantSwiftTestingSuite.self,
      input: """
        import Testing

        /// This is a test suite
        1️⃣@Suite
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """,
      expected: """
        import Testing

        /// This is a test suite
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@Suite' attribute; it is inferred by Swift Testing"),
      ]
    )
  }
}
