struct EmptyCollectionLiteralConfiguration: RuleConfiguration {
    let id = "empty_collection_literal"
    let name = "Empty Collection Literal"
    let summary = "Prefer checking `isEmpty` over comparing collection to an empty array or dictionary literal"
    let isOptIn = true
}
