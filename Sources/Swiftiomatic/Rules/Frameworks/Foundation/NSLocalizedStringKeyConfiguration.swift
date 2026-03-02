struct NSLocalizedStringKeyConfiguration: RuleConfiguration {
    let id = "nslocalizedstring_key"
    let name = "NSLocalizedString Key"
    let summary = "Static strings should be used as key/comment in NSLocalizedString in order for genstrings to work"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("NSLocalizedString(\"key\", comment: \"\")"),
              Example("NSLocalizedString(\"key\" + \"2\", comment: \"\")"),
              Example("NSLocalizedString(\"key\", comment: \"comment\")"),
              Example(
                """
                NSLocalizedString("This is a multi-" +
                    "line string", comment: "")
                """,
              ),
              Example(
                """
                let format = NSLocalizedString("%@, %@.", comment: "Accessibility label for a post in the post list." +
                " The parameters are the title, and date respectively." +
                " For example, \"Let it Go, 1 hour ago.\"")
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("NSLocalizedString(↓method(), comment: \"\")"),
              Example("NSLocalizedString(↓\"key_\\(param)\", comment: \"\")"),
              Example("NSLocalizedString(\"key\", comment: ↓\"comment with \\(param)\")"),
              Example("NSLocalizedString(↓\"key_\\(param)\", comment: ↓method())"),
            ]
    }
}
