@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct MutableCaptureTests: RuleTesting {
  @Test func localVarCapture() {
    assertLint(
      MutableCapture.self,
      """
      func foo() {
        var counter = 0
        let closure = { [1️⃣counter] in
          print(counter)
        }
        counter = 1
        closure()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "captured variable 'counter' is declared with 'var'; closure captures the value at creation time, not subsequent mutations"),
      ]
    )
  }

  @Test func instanceVarCapture() {
    assertLint(
      MutableCapture.self,
      """
      class C {
        var iInstance: Int = 0
        func callTest() {
          test { [1️⃣iInstance] j in
            print(iInstance, j)
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "captured variable 'iInstance' is declared with 'var'; closure captures the value at creation time, not subsequent mutations"),
      ]
    )
  }

  @Test func staticVarCapture() {
    assertLint(
      MutableCapture.self,
      """
      class C {
        static var iStatic: Int = 0
        static func callTest() {
          test { [1️⃣iStatic] j in
            print(iStatic, j)
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "captured variable 'iStatic' is declared with 'var'; closure captures the value at creation time, not subsequent mutations"),
      ]
    )
  }

  @Test func letCaptureDoesNotTrigger() {
    assertLint(
      MutableCapture.self,
      """
      func foo() {
        let j = 0
        let c = C(1)
        let closure = { [j, c] in
          print(c.i, j)
        }
        closure()
      }
      """,
      findings: []
    )
  }

  @Test func selfCaptureDoesNotTrigger() {
    assertLint(
      MutableCapture.self,
      """
      class C {
        var x = 0
        func foo() {
          test { [self] in
            print(x)
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func weakAndUnownedDoNotTrigger() {
    assertLint(
      MutableCapture.self,
      """
      class C {
        var ref: AnyObject?
        func foo() {
          test { [weak ref, unowned other] in
            _ = ref
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func captureWithExplicitInitializerDoesNotTrigger() {
    assertLint(
      MutableCapture.self,
      """
      class C {
        var x = 0
        func foo() {
          test { [x = self.x] in
            print(x)
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func multipleMutableCaptures() {
    assertLint(
      MutableCapture.self,
      """
      func foo() {
        var a = 0
        var b = 0
        let closure = { [1️⃣a, 2️⃣b] in
          print(a, b)
        }
        closure()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "captured variable 'a' is declared with 'var'; closure captures the value at creation time, not subsequent mutations"),
        FindingSpec("2️⃣", message: "captured variable 'b' is declared with 'var'; closure captures the value at creation time, not subsequent mutations"),
      ]
    )
  }
}
