struct UnavailableConditionConfiguration: RuleConfiguration {
    let id = "unavailable_condition"
    let name = "Unavailable Condition"
    let summary = "Use #unavailable/#available instead of #available/#unavailable with an empty body."
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                if #unavailable(iOS 13) {
                  loadMainWindow()
                }
                """,
              ),
              Example(
                """
                if #available(iOS 9.0, *) {
                  doSomething()
                } else {
                  legacyDoSomething()
                }
                """,
              ),
              Example(
                """
                if #available(macOS 11.0, *) {
                   // Do nothing
                } else if #available(macOS 10.15, *) {
                   print("do some stuff")
                }
                """,
              ),
              Example(
                """
                if #available(macOS 11.0, *) {
                   // Do nothing
                } else if i > 7 {
                   print("do some stuff")
                } else if i < 2, #available(macOS 11.0, *) {
                  print("something else")
                }
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                if ↓#available(iOS 14.0) {

                } else {
                  oldIos13TrackingLogic(isEnabled: ASIdentifierManager.shared().isAdvertisingTrackingEnabled)
                }
                """,
              ),
              Example(
                """
                if ↓#available(iOS 14.0) {
                  // we don't need to do anything here
                } else {
                  oldIos13TrackingLogic(isEnabled: ASIdentifierManager.shared().isAdvertisingTrackingEnabled)
                }
                """,
              ),
              Example(
                """
                if ↓#available(iOS 13, *) {} else {
                  loadMainWindow()
                }
                """,
              ),
              Example(
                """
                if ↓#unavailable(iOS 13) {
                  // Do nothing
                } else if i < 2 {
                  loadMainWindow()
                }
                """,
              ),
            ]
    }
}
