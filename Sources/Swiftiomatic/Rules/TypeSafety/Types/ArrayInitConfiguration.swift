struct ArrayInitConfiguration: RuleConfiguration {
    let id = "array_init"
    let name = "Array Init"
    let summary = "Prefer using `Array(seq)` over `seq.map { $0 }` to convert a sequence into an Array"
    let isOptIn = true
}
