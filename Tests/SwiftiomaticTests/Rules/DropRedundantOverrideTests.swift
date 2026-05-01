@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropRedundantOverrideTests: RuleTesting {
  @Test func plainForward() {
    assertFormatting(
      DropRedundantOverride.self,
      input: """
        class Foo: Bar {
          1️⃣override func update() {
            super.update()
          }
        }
        """,
      expected: """
        class Foo: Bar {
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "remove redundant override of 'update'; it only forwards to super with identical arguments"
        ),
      ]
    )
  }

  @Test func forwardWithLabeledArgs() {
    assertFormatting(
      DropRedundantOverride.self,
      input: """
        class Foo: Bar {
          1️⃣override func setEditing(_ editing: Bool, animated: Bool) {
            super.setEditing(editing, animated: animated)
          }
        }
        """,
      expected: """
        class Foo: Bar {
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "remove redundant override of 'setEditing'; it only forwards to super with identical arguments"
        ),
      ]
    )
  }

  @Test func extraStatementNotFlagged() {
    assertFormatting(
      DropRedundantOverride.self,
      input: """
        class Foo: Bar {
          override func update() {
            super.update()
            log("did update")
          }
        }
        """,
      expected: """
        class Foo: Bar {
          override func update() {
            super.update()
            log("did update")
          }
        }
        """,
      findings: []
    )
  }

  @Test func differentArgumentsNotFlagged() {
    assertFormatting(
      DropRedundantOverride.self,
      input: """
        class Foo: Bar {
          override func setEditing(_ editing: Bool, animated: Bool) {
            super.setEditing(editing, animated: false)
          }
        }
        """,
      expected: """
        class Foo: Bar {
          override func setEditing(_ editing: Bool, animated: Bool) {
            super.setEditing(editing, animated: false)
          }
        }
        """,
      findings: []
    )
  }

  @Test func excludedTestLifecycleNotFlagged() {
    assertFormatting(
      DropRedundantOverride.self,
      input: """
        class FooTests: XCTestCase {
          override func setUp() {
            super.setUp()
          }
        }
        """,
      expected: """
        class FooTests: XCTestCase {
          override func setUp() {
            super.setUp()
          }
        }
        """,
      findings: []
    )
  }

  @Test func attributedOverrideNotFlagged() {
    assertFormatting(
      DropRedundantOverride.self,
      input: """
        class Foo: Bar {
          @available(*, deprecated)
          override func update() {
            super.update()
          }
        }
        """,
      expected: """
        class Foo: Bar {
          @available(*, deprecated)
          override func update() {
            super.update()
          }
        }
        """,
      findings: []
    )
  }

  @Test func tryAwaitForward() {
    assertFormatting(
      DropRedundantOverride.self,
      input: """
        class Foo: Bar {
          1️⃣override func load() async throws {
            try await super.load()
          }
        }
        """,
      expected: """
        class Foo: Bar {
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "remove redundant override of 'load'; it only forwards to super with identical arguments"
        ),
      ]
    )
  }

  @Test func tryBangNotFlagged() {
    assertFormatting(
      DropRedundantOverride.self,
      input: """
        class Foo: Bar {
          override func load() {
            try! super.load()
          }
        }
        """,
      expected: """
        class Foo: Bar {
          override func load() {
            try! super.load()
          }
        }
        """,
      findings: []
    )
  }

  @Test func staticOverrideNotFlagged() {
    assertFormatting(
      DropRedundantOverride.self,
      input: """
        class Foo: Bar {
          override static func register() {
            super.register()
          }
        }
        """,
      expected: """
        class Foo: Bar {
          override static func register() {
            super.register()
          }
        }
        """,
      findings: []
    )
  }
}
