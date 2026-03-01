struct NSNumberInitAsFunctionReferenceConfiguration: RuleConfiguration {
    let id = "ns_number_init_as_function_reference"
    let name = "NSNumber Init as Function Reference"
    let summary = "Passing `NSNumber.init` or `NSDecimalNumber.init` as a function reference is dangerous as it can cause the wrong initializer to be used, causing crashes; use `.init(value:)` instead"
}
