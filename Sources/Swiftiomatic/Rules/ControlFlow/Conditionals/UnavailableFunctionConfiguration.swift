struct UnavailableFunctionConfiguration: RuleConfiguration {
    let id = "unavailable_function"
    let name = "Unavailable Function"
    let summary = "Unimplemented functions should be marked as unavailable"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class ViewController: UIViewController {
                  @available(*, unavailable)
                  public required init?(coder aDecoder: NSCoder) {
                    preconditionFailure("init(coder:) has not been implemented")
                  }
                }
                """,
              ),
              Example(
                """
                func jsonValue(_ jsonString: String) -> NSObject {
                   let data = jsonString.data(using: .utf8)!
                   let result = try! JSONSerialization.jsonObject(with: data, options: [])
                   if let dict = (result as? [String: Any])?.bridge() {
                    return dict
                   } else if let array = (result as? [Any])?.bridge() {
                    return array
                   }
                   fatalError()
                }
                """,
              ),
              Example(
                """
                func resetOnboardingStateAndCrash() -> Never {
                    resetUserDefaults()
                    // Crash the app to re-start the onboarding flow.
                    fatalError("Onboarding re-start crash.")
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                class ViewController: UIViewController {
                  public required ↓init?(coder aDecoder: NSCoder) {
                    fatalError("init(coder:) has not been implemented")
                  }
                }
                """,
              ),
              Example(
                """
                class ViewController: UIViewController {
                  public required ↓init?(coder aDecoder: NSCoder) {
                    let reason = "init(coder:) has not been implemented"
                    fatalError(reason)
                  }
                }
                """,
              ),
              Example(
                """
                class ViewController: UIViewController {
                  public required ↓init?(coder aDecoder: NSCoder) {
                    preconditionFailure("init(coder:) has not been implemented")
                  }
                }
                """,
              ),
              Example(
                """
                ↓func resetOnboardingStateAndCrash() {
                    resetUserDefaults()
                    // Crash the app to re-start the onboarding flow.
                    fatalError("Onboarding re-start crash.")
                }
                """,
              ),
            ]
    }
}
