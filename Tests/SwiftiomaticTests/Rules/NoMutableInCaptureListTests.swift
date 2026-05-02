@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoMutableInCaptureListTests: RuleTesting {
  @Test func explicitMutableCaptureFlagged() {
    assertLint(
      NoMutableInCaptureList.self,
      """
      func foo() {
        var counter = 0
        let closure: () -> Void = { [1️⃣counter] in
          print(counter)
        }
        counter = 1
        closure()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "explicit `[counter]` captures a mutable `var` by value at closure-creation time; subsequent mutations through the original binding are invisible to the closure — drop the capture list, rename the var, or use `[counter = counter]` to make the value-snapshot intent explicit"),
      ]
    )
  }

  @Test func multipleMutableCapturesFlagged() {
    assertLint(
      NoMutableInCaptureList.self,
      """
      func foo() {
        var a = 0
        var b = 0
        let closure = { [1️⃣a, 2️⃣b] in
          print(a, b)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "explicit `[a]` captures a mutable `var` by value at closure-creation time; subsequent mutations through the original binding are invisible to the closure — drop the capture list, rename the var, or use `[a = a]` to make the value-snapshot intent explicit"),
        FindingSpec("2️⃣", message: "explicit `[b]` captures a mutable `var` by value at closure-creation time; subsequent mutations through the original binding are invisible to the closure — drop the capture list, rename the var, or use `[b = b]` to make the value-snapshot intent explicit"),
      ]
    )
  }

  @Test func implicitReferenceNotFlagged() {
    // Implicit references are not the rule's target. Only bare names listed
    // inside the capture brackets are inspected.
    assertLint(
      NoMutableInCaptureList.self,
      """
      func foo() {
        var counter = 0
        let closure = {
          print(counter)
        }
        counter = 1
        closure()
      }
      """,
      findings: []
    )
  }

  @Test func explicitRebindingNotFlagged() {
    // `[x = self.x]` and `[x = x]` document value-snapshot intent.
    assertLint(
      NoMutableInCaptureList.self,
      """
      func foo() {
        var x = 0
        let closure = { [x = x] in
          print(x)
        }
      }
      """,
      findings: []
    )
  }

  @Test func weakCaptureNotFlagged() {
    assertLint(
      NoMutableInCaptureList.self,
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

  @Test func unownedCaptureNotFlagged() {
    assertLint(
      NoMutableInCaptureList.self,
      """
      class C {
        var ref: AnyObject?
        func foo() {
          test { [unowned ref] in
            _ = ref
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func selfCaptureNotFlagged() {
    assertLint(
      NoMutableInCaptureList.self,
      """
      class C {
        func foo() {
          test { [self] in
            _ = self
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func letBindingNotFlagged() {
    assertLint(
      NoMutableInCaptureList.self,
      """
      func foo() {
        let j = 0
        let closure = { [j] in
          print(j)
        }
      }
      """,
      findings: []
    )
  }

  @Test func iuoVarNotFlagged() {
    // `var x: Int!` is the late-init idiom; not the snapshot footgun.
    assertLint(
      NoMutableInCaptureList.self,
      """
      func foo() {
        var x: Int! = 0
        let closure = { [x] in
          print(x)
        }
      }
      """,
      findings: []
    )
  }

  @Test func lazyVarNotFlagged() {
    assertLint(
      NoMutableInCaptureList.self,
      """
      class C {
        lazy var x: Int = 0
      }
      func foo() {
        let closure = { [x] in
          print(x)
        }
      }
      """,
      findings: []
    )
  }

  @Test func storedPropertyOfTypeNotFlagged() {
    // Stored `var` properties on types are accessed through `self`, not as
    // bare-name captures. They're not collected as candidates.
    assertLint(
      NoMutableInCaptureList.self,
      """
      class C {
        var counter = 0
        func foo() {
          test { [counter] in
            _ = counter
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func attributedVarNotFlagged() {
    // @State / @Bindable / @Binding / @FocusState / @AppStorage etc. are
    // property-wrapper bindings whose runtime semantics are reference-like.
    assertLint(
      NoMutableInCaptureList.self,
      """
      struct V: View {
        @State var disabled = false
        var body: some View {
          @Bindable var disabled = self
          Button("X") { [disabled] in print(disabled) }
        }
      }
      """,
      findings: []
    )
  }

  @Test func nestedClosureExplicitCaptureFlagged() {
    assertLint(
      NoMutableInCaptureList.self,
      """
      func foo() {
        var counter = 0
        outer {
          inner { [1️⃣counter] in
            print(counter)
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "explicit `[counter]` captures a mutable `var` by value at closure-creation time; subsequent mutations through the original binding are invisible to the closure — drop the capture list, rename the var, or use `[counter = counter]` to make the value-snapshot intent explicit"),
      ]
    )
  }

  @Test func sendableHandOffWithExplicitCaptureFlagged() {
    // The classic Sendable hand-off pattern: developer thinks `[groupID]` is
    // safer, but it's actually the snapshot footgun this rule targets.
    assertLint(
      NoMutableInCaptureList.self,
      """
      func foo() {
        var groupID = 0
        sqlite.read { [1️⃣groupID] in
          try Node.fetch(for: groupID, from: $0)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "explicit `[groupID]` captures a mutable `var` by value at closure-creation time; subsequent mutations through the original binding are invisible to the closure — drop the capture list, rename the var, or use `[groupID = groupID]` to make the value-snapshot intent explicit"),
      ]
    )
  }
}
