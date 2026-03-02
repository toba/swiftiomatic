struct NSNumberInitAsFunctionReferenceConfiguration: RuleConfiguration {
    let id = "ns_number_init_as_function_reference"
    let name = "NSNumber Init as Function Reference"
    let summary = "Passing `NSNumber.init` or `NSDecimalNumber.init` as a function reference is dangerous as it can cause the wrong initializer to be used, causing crashes; use `.init(value:)` instead"
    var nonTriggeringExamples: [Example] {
        [
              Example("[0, 0.2].map(NSNumber.init(value:))"),
              Example("let value = NSNumber.init(value: 0.0)"),
              Example("[0, 0.2].map { NSNumber(value: $0) }"),
              Example("[0, 0.2].map(NSDecimalNumber.init(value:))"),
              Example("[0, 0.2].map { NSDecimalNumber(value: $0) }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("[0, 0.2].map(↓NSNumber.init)"),
              Example("[0, 0.2].map(↓NSDecimalNumber.init)"),
            ]
    }
}
