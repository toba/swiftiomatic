struct TypesafeArrayInitConfiguration: RuleConfiguration {
    let id = "typesafe_array_init"
    let name = "Type-safe Array Init"
    let summary = "Prefer using `Array(seq)` over `seq.map { $0 }` to convert a sequence into an Array"
    let isCorrectable = true
    let isOptIn = true
    let requiresSourceKit = true
    let requiresCompilerArguments = true
    let requiresFileOnDisk = true
}
