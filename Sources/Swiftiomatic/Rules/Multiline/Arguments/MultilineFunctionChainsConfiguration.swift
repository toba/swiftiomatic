struct MultilineFunctionChainsConfiguration: RuleConfiguration {
    let id = "multiline_function_chains"
    let name = "Multiline Function Chains"
    let summary = "Chained function calls should be either on the same line, or one per line"
    let isOptIn = true
    let requiresSourceKit = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                "let evenSquaresSum = [20, 17, 35, 4].filter { $0 % 2 == 0 }.map { $0 * $0 }.reduce(0, +)",
              ),
              Example(
                """
                let evenSquaresSum = [20, 17, 35, 4]
                    .filter { $0 % 2 == 0 }.map { $0 * $0 }.reduce(0, +)",
                """,
              ),
              Example(
                """
                let chain = a
                    .b(1, 2, 3)
                    .c { blah in
                        print(blah)
                    }
                    .d()
                """,
              ),
              Example(
                """
                let chain = a.b(1, 2, 3)
                    .c { blah in
                        print(blah)
                    }
                    .d()
                """,
              ),
              Example(
                """
                let chain = a.b(1, 2, 3)
                    .c { blah in print(blah) }
                    .d()
                """,
              ),
              Example(
                """
                let chain = a.b(1, 2, 3)
                    .c(.init(
                        a: 1,
                        b, 2,
                        c, 3))
                    .d()
                """,
              ),
              Example(
                """
                self.viewModel.outputs.postContextualNotification
                  .observeForUI()
                  .observeValues {
                    NotificationCenter.default.post(
                      Notification(
                        name: .ksr_showNotificationsDialog,
                        userInfo: [UserInfoKeys.context: PushNotificationDialog.Context.pledge,
                                   UserInfoKeys.viewController: self]
                     )
                    )
                  }
                """,
              ),
              Example(
                "let remainingIDs = Array(Set(self.currentIDs).subtracting(Set(response.ids)))",
              ),
              Example(
                """
                self.happeningNewsletterOn = self.updateCurrentUser
                    .map { $0.newsletters.happening }.skipNil().skipRepeats()
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                let evenSquaresSum = [20, 17, 35, 4]
                    .filter { $0 % 2 == 0 }↓.map { $0 * $0 }
                    .reduce(0, +)
                """,
              ),
              Example(
                """
                let evenSquaresSum = a.b(1, 2, 3)
                    .c { blah in
                        print(blah)
                    }↓.d()
                """,
              ),
              Example(
                """
                let evenSquaresSum = a.b(1, 2, 3)
                    .c(2, 3, 4)↓.d()
                """,
              ),
              Example(
                """
                let evenSquaresSum = a.b(1, 2, 3)↓.c { blah in
                        print(blah)
                    }
                    .d()
                """,
              ),
              Example(
                """
                a.b {
                //  ““
                }↓.e()
                """,
              ),
            ]
    }
}
