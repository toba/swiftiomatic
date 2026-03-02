struct NSLocalizedStringRequireBundleConfiguration: RuleConfiguration {
    let id = "nslocalizedstring_require_bundle"
    let name = "NSLocalizedString Require Bundle"
    let summary = "Calls to NSLocalizedString should specify the bundle which contains the strings file"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                NSLocalizedString("someKey", bundle: .main, comment: "test")
                """,
              ),
              Example(
                """
                NSLocalizedString("someKey", tableName: "a",
                                  bundle: Bundle(for: A.self),
                                  comment: "test")
                """,
              ),
              Example(
                """
                NSLocalizedString("someKey", tableName: "xyz",
                                  bundle: someBundle, value: "test"
                                  comment: "test")
                """,
              ),
              Example(
                """
                arbitraryFunctionCall("something")
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓NSLocalizedString("someKey", comment: "test")
                """,
              ),
              Example(
                """
                ↓NSLocalizedString("someKey", tableName: "a", comment: "test")
                """,
              ),
              Example(
                """
                ↓NSLocalizedString("someKey", tableName: "xyz",
                                  value: "test", comment: "test")
                """,
              ),
            ]
    }
}
