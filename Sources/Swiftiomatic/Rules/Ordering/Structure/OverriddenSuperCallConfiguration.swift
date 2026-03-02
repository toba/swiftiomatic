struct OverriddenSuperCallConfiguration: RuleConfiguration {
    let id = "overridden_super_call"
    let name = "Overridden Method Calls Super"
    let summary = "Some overridden methods should always call super."
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class VC: UIViewController {
                    override func viewWillAppear(_ animated: Bool) {
                        super.viewWillAppear(animated)
                    }
                }
                """,
              ),
              Example(
                """
                class VC: UIViewController {
                    override func viewWillAppear(_ animated: Bool) {
                        self.method1()
                        super.viewWillAppear(animated)
                        self.method2()
                    }
                }
                """,
              ),
              Example(
                """
                class VC: UIViewController {
                    override func loadView() {
                    }
                }
                """,
              ),
              Example(
                """
                class Some {
                    func viewWillAppear(_ animated: Bool) {
                    }
                }
                """,
              ),
              Example(
                """
                class VC: UIViewController {
                    override func viewDidLoad() {
                    defer {
                        super.viewDidLoad()
                        }
                    }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                class VC: UIViewController {
                    override func viewWillAppear(_ animated: Bool) {↓
                        //Not calling to super
                        self.method()
                    }
                }
                """,
              ),
              Example(
                """
                class VC: UIViewController {
                    override func viewWillAppear(_ animated: Bool) {↓
                        super.viewWillAppear(animated)
                        //Other code
                        super.viewWillAppear(animated)
                    }
                }
                """,
              ),
              Example(
                """
                class VC: UIViewController {
                    override func didReceiveMemoryWarning() {↓
                    }
                }
                """,
              ),
            ]
    }
}
