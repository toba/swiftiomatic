struct NoFallthroughOnlyConfiguration: RuleConfiguration {
    let id = "no_fallthrough_only"
    let name = "No Fallthrough only"
    let summary = "Fallthroughs can only be used if the `case` contains at least one other statement"
}
