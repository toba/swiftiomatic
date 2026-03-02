struct ReturnValueFromVoidFunctionConfiguration: RuleConfiguration {
    let id = "return_value_from_void_function"
    let name = "Return Value from Void Function"
    let summary = "Returning values from Void functions should be avoided"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        ReturnValueFromVoidFunctionRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        ReturnValueFromVoidFunctionRuleExamples.triggeringExamples
    }
}
