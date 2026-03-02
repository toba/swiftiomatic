struct IsDisjointConfiguration: RuleConfiguration {
    let id = "is_disjoint"
    let name = "Is Disjoint"
    let summary = "Prefer using `Set.isDisjoint(with:)` over `Set.intersection(_:).isEmpty`"
    var nonTriggeringExamples: [Example] {
        [
              Example("_ = Set(syntaxKinds).isDisjoint(with: commentAndStringKindsSet)"),
              Example(
                "let isObjc = !objcAttributes.isDisjoint(with: dictionary.enclosedSwiftAttributes)",
              ),
              Example("_ = Set(syntaxKinds).intersection(commentAndStringKindsSet)"),
              Example("_ = !objcAttributes.intersection(dictionary.enclosedSwiftAttributes)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("_ = Set(syntaxKinds).↓intersection(commentAndStringKindsSet).isEmpty"),
              Example(
                "let isObjc = !objcAttributes.↓intersection(dictionary.enclosedSwiftAttributes).isEmpty",
              ),
            ]
    }
}
