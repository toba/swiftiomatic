struct ForceCastConfiguration: RuleConfiguration {
    let id = "force_cast"
    let name = "Force Cast"
    let summary = "Force casts should be avoided"
    var nonTriggeringExamples: [Example] {
        [
              Example("NSNumber() as? Int")
            ]
    }
    var triggeringExamples: [Example] {
        [Example("NSNumber() ↓as! Int")]
    }
}
