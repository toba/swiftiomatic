struct BlockBasedKVOConfiguration: RuleConfiguration {
    let id = "block_based_kvo"
    let name = "Block Based KVO"
    let summary = "Prefer the new block based KVO API with keypaths when using Swift 3.2 or later"
}
