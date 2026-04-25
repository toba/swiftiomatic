@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireSuperCallTests: RuleTesting {
  @Test func missingSuperCallInViewWillAppear() {
    assertLint(
      RequireSuperCall.self,
      """
      class VC: UIViewController {
        override func 1️⃣viewWillAppear(_ animated: Bool) {
          self.method()
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "override of 'viewWillAppear(_:)' should call super"),
      ]
    )
  }

  @Test func presentSuperCallDoesNotTrigger() {
    assertLint(
      RequireSuperCall.self,
      """
      class VC: UIViewController {
        override func viewWillAppear(_ animated: Bool) {
          super.viewWillAppear(animated)
        }
      }
      """,
      findings: []
    )
  }

  @Test func superCallAroundOtherCodeDoesNotTrigger() {
    assertLint(
      RequireSuperCall.self,
      """
      class VC: UIViewController {
        override func viewWillAppear(_ animated: Bool) {
          self.method1()
          super.viewWillAppear(animated)
          self.method2()
        }
      }
      """,
      findings: []
    )
  }

  @Test func multipleSuperCallsTrigger() {
    assertLint(
      RequireSuperCall.self,
      """
      class VC: UIViewController {
        override func 1️⃣viewWillAppear(_ animated: Bool) {
          super.viewWillAppear(animated)
          super.viewWillAppear(animated)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "override of 'viewWillAppear(_:)' should call super exactly once, not multiple times"),
      ]
    )
  }

  @Test func nonOverrideMethodNotChecked() {
    assertLint(
      RequireSuperCall.self,
      """
      class Some {
        func viewWillAppear(_ animated: Bool) {}
      }
      """,
      findings: []
    )
  }

  @Test func nonRequiredMethodNotChecked() {
    assertLint(
      RequireSuperCall.self,
      """
      class VC: UIViewController {
        override func loadView() {}
      }
      """,
      findings: []
    )
  }

  @Test func didReceiveMemoryWarningEmptyBodyTriggers() {
    assertLint(
      RequireSuperCall.self,
      """
      class VC: UIViewController {
        override func 1️⃣didReceiveMemoryWarning() {
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "override of 'didReceiveMemoryWarning()' should call super"),
      ]
    )
  }

  @Test func superCallInsideDeferDoesNotTrigger() {
    assertLint(
      RequireSuperCall.self,
      """
      class VC: UIViewController {
        override func viewDidLoad() {
          defer {
            super.viewDidLoad()
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func staticMethodNotChecked() {
    assertLint(
      RequireSuperCall.self,
      """
      class VC: UIViewController {
        override static func viewDidLoad() {}
      }
      """,
      findings: []
    )
  }
}
