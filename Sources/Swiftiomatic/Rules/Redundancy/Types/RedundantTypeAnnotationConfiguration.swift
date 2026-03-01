struct RedundantTypeAnnotationConfiguration: RuleConfiguration {
    let id = "redundant_type_annotation"
    let name = "Redundant Type Annotation"
    let summary = "Variables should not have redundant type annotation"
    let isCorrectable = true
    let isOptIn = true
}
