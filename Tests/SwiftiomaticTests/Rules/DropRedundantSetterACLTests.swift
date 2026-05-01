@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropRedundantSetterACLTests: RuleTesting {
  @Test func privateSetMatchingPrivate() {
    assertFormatting(
      DropRedundantSetterACL.self,
      input: """
        class Foo {
          1️⃣private(set) private var value: Int = 0
        }
        """,
      expected: """
        class Foo {
          private var value: Int = 0
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove redundant 'private(set)'; it matches the property's access level"
        ),
      ]
    )
  }

  @Test func internalSetInsideInternalType() {
    assertFormatting(
      DropRedundantSetterACL.self,
      input: """
        internal class Foo {
          1️⃣internal(set) var value: Int = 0
        }
        """,
      expected: """
        internal class Foo {
          var value: Int = 0
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove redundant 'internal(set)'; it matches the enclosing type's access level"
        ),
      ]
    )
  }

  @Test func internalSetInsideDefaultType() {
    assertFormatting(
      DropRedundantSetterACL.self,
      input: """
        class Foo {
          1️⃣internal(set) var value: Int = 0
        }
        """,
      expected: """
        class Foo {
          var value: Int = 0
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove redundant 'internal(set)'; it matches the enclosing type's access level"
        ),
      ]
    )
  }

  @Test func fileprivateSetInsideFileprivateType() {
    assertFormatting(
      DropRedundantSetterACL.self,
      input: """
        fileprivate class Foo {
          1️⃣fileprivate(set) var value: Int = 0
        }
        """,
      expected: """
        fileprivate class Foo {
          var value: Int = 0
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "remove redundant 'fileprivate(set)'; it matches the enclosing type's access level"
        ),
      ]
    )
  }

  @Test func publicSetMatchingPublic() {
    assertFormatting(
      DropRedundantSetterACL.self,
      input: """
        1️⃣public(set) public var value: Int = 0
        """,
      expected: """
        public var value: Int = 0
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove redundant 'public(set)'; it matches the property's access level"
        ),
      ]
    )
  }

  @Test func differingGetterAndSetterNotFlagged() {
    assertFormatting(
      DropRedundantSetterACL.self,
      input: """
        public class Foo {
          private(set) public var value: Int = 0
        }
        """,
      expected: """
        public class Foo {
          private(set) public var value: Int = 0
        }
        """,
      findings: []
    )
  }

  @Test func internalSetInsidePublicTypeNotFlagged() {
    assertFormatting(
      DropRedundantSetterACL.self,
      input: """
        public class Foo {
          internal(set) public var value: Int = 0
        }
        """,
      expected: """
        public class Foo {
          internal(set) public var value: Int = 0
        }
        """,
      findings: []
    )
  }

  @Test func plainPropertyNotFlagged() {
    assertFormatting(
      DropRedundantSetterACL.self,
      input: """
        class Foo {
          var value: Int = 0
        }
        """,
      expected: """
        class Foo {
          var value: Int = 0
        }
        """,
      findings: []
    )
  }
}
