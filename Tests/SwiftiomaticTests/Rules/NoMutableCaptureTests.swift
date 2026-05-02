@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoMutableCaptureTests: RuleTesting {
  @Test func implicitLocalVarReferenceFlagged() {
    assertLint(
      NoMutableCapture.self,
      """
      func foo() {
        var counter = 0
        let closure = {
          print(1️⃣counter)
        }
        counter = 1
        closure()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "closure implicitly captures mutable variable 'counter'; add it to the capture list (`[counter]`) to snapshot the current value, or rename to avoid collision"),
      ]
    )
  }

  @Test func explicitCaptureListIsNotFlagged() {
    assertLint(
      NoMutableCapture.self,
      """
      func foo() {
        var counter = 0
        let closure = { [counter] in
          print(counter)
        }
        counter = 1
        closure()
      }
      """,
      findings: []
    )
  }

  @Test func sendableHandOffWithExplicitCaptureNotFlagged() {
    assertLint(
      NoMutableCapture.self,
      """
      func foo() {
        var groupID = 0
        sqlite.read { [groupID] in
          try Node.fetch(for: groupID, from: $0)
        }
      }
      """,
      findings: []
    )
  }

  @Test func multipleExplicitCapturesNotFlagged() {
    assertLint(
      NoMutableCapture.self,
      """
      func foo() {
        var missingTable: Int? = 0
        var missingRecord: Int? = 0
        var sentRecord: Int? = 0
        state.withLock { [missingTable, missingRecord, sentRecord] in
          if let missingTable {}
        }
      }
      """,
      findings: []
    )
  }

  @Test func memberAccessNotFlagged() {
    assertLint(
      NoMutableCapture.self,
      """
      class C {
        var counter = 0
        func foo() {
          test {
            print(self.counter)
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func letBindingNotFlagged() {
    assertLint(
      NoMutableCapture.self,
      """
      func foo() {
        let j = 0
        let closure = {
          print(j)
        }
      }
      """,
      findings: []
    )
  }

  @Test func closureParameterShadowsVar() {
    assertLint(
      NoMutableCapture.self,
      """
      func foo() {
        var counter = 0
        let closure: (Int) -> Void = { counter in
          print(counter)
        }
      }
      """,
      findings: []
    )
  }

  @Test func localBindingShadowsVar() {
    assertLint(
      NoMutableCapture.self,
      """
      func foo() {
        var counter = 0
        let closure = {
          let counter = 42
          print(counter)
        }
      }
      """,
      findings: []
    )
  }

  @Test func multipleImplicitReferencesFlagged() {
    assertLint(
      NoMutableCapture.self,
      """
      func foo() {
        var a = 0
        var b = 0
        let closure = {
          print(1️⃣a, 2️⃣b)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "closure implicitly captures mutable variable 'a'; add it to the capture list (`[a]`) to snapshot the current value, or rename to avoid collision"),
        FindingSpec("2️⃣", message: "closure implicitly captures mutable variable 'b'; add it to the capture list (`[b]`) to snapshot the current value, or rename to avoid collision"),
      ]
    )
  }

  @Test func nestedClosureScopeIsolated() {
    // Outer closure has no `counter` reference; inner closure references `counter`.
    // Inner closure should be flagged independently.
    assertLint(
      NoMutableCapture.self,
      """
      func foo() {
        var counter = 0
        outer {
          inner {
            print(1️⃣counter)
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "closure implicitly captures mutable variable 'counter'; add it to the capture list (`[counter]`) to snapshot the current value, or rename to avoid collision"),
      ]
    )
  }

  @Test func enclosingClosureExplicitCaptureShadowsInner() {
    // Inner closure has no own capture list, but the enclosing closure explicitly
    // captures `changes` — so `changes` inside the inner closure resolves to the
    // outer let, not the file-level var. Should not flag.
    assertLint(
      NoMutableCapture.self,
      """
      func foo() {
        var changes: [Int] = []
        Task { [changes] in
          outer {
            inner {
              _ = changes.map { String($0) }
            }
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func enclosingClosureParameterShadowsInner() {
    assertLint(
      NoMutableCapture.self,
      """
      func foo() {
        var counter = 0
        outer { counter in
          inner {
            print(counter)
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func captureWithExplicitInitializerNotFlagged() {
    assertLint(
      NoMutableCapture.self,
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

  @Test func storedPropertyOfTypeNotFlaggedInMemberClosure() {
    // Stored `var` properties on a type (SwiftUI views, classes, structs) are
    // accessed via implicit `self`, not implicit local capture. They must not
    // be treated as candidates for the implicit-capture rule.
    assertLint(
      NoMutableCapture.self,
      """
      struct ToolbarView: View {
        @Binding var editor: Editor
        @State var disabled = false
        @State var controlSize: ControlSize = .regular
        var body: some View {
          Button("Tap") {
            print(editor, disabled, controlSize)
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func storedPropertyOnClassNotFlaggedInMethodClosure() {
    assertLint(
      NoMutableCapture.self,
      """
      class C {
        var counter = 0
        func foo() {
          run { print(counter) }
        }
      }
      """,
      findings: []
    )
  }

  @Test func enclosingFunctionLetShadowsUnrelatedFileVar() {
    // `var query` exists in an unrelated scope. The closure references `query`
    // which is bound by a `let` in the enclosing function body — should not flag.
    assertLint(
      NoMutableCapture.self,
      """
      func other() {
        var query = ""
      }
      func bar() async throws {
        let query = "SELECT"
        try await db.write { db in
          try #sql(query).execute(db)
        }
      }
      """,
      findings: []
    )
  }

  @Test func enclosingFunctionParameterShadowsVar() {
    assertLint(
      NoMutableCapture.self,
      """
      func other() { var counter = 0 }
      func bar(counter: Int) {
        run { print(counter) }
      }
      """,
      findings: []
    )
  }

  @Test func enclosingForLoopBindingShadowsVar() {
    assertLint(
      NoMutableCapture.self,
      """
      func other() { var name = "" }
      func bar(items: [String]) {
        for name in items {
          run { print(name) }
        }
      }
      """,
      findings: []
    )
  }

  @Test func weakAndUnownedCapturesNotFlagged() {
    assertLint(
      NoMutableCapture.self,
      """
      class C {
        var ref: AnyObject?
        func foo() {
          test { [weak ref] in
            _ = ref
          }
        }
      }
      """,
      findings: []
    )
  }
}
