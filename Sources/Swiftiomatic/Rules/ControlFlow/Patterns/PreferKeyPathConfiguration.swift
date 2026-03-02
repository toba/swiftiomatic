struct PreferKeyPathConfiguration: RuleConfiguration {
    private static let extendedMode = ["restrict_to_standard_functions": false]
    private static let ignoreIdentity = ["ignore_identity_closures": true]
    private static let extendedModeAndIgnoreIdentity = [
        "restrict_to_standard_functions": false,
        "ignore_identity_closures": true,
    ]
    let id = "prefer_key_path"
    let name = "Prefer Key Path"
    let summary = "Use a key path argument instead of a closure with property access"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("f {}"),
              Example("f { $0 }"),
              Example("f { $0.a }"),
              Example("let f = { $0.a }(b)"),
              Example("f {}", configuration: Self.extendedMode),
              Example("f() { g() }", configuration: Self.extendedMode),
              Example("f { a.b.c }", configuration: Self.extendedMode),
              Example("f { a, b in a.b }", configuration: Self.extendedMode),
              Example("f { (a, b) in a.b }", configuration: Self.extendedMode),
              Example("f { $0.a } g: { $0.b }", configuration: Self.extendedMode),
              Example("[1, 2, 3].reduce(1) { $0 + $1 }", configuration: Self.extendedMode),
              Example("f { $0 }", configuration: Self.extendedModeAndIgnoreIdentity),
              Example("f.map { $0 }", configuration: Self.ignoreIdentity),
              Example("f.map(1) { $0.a }"),
              Example("f.filter({ $0.a }, x)"),
              Example("#Predicate { $0.a }"),
              Example("let transform: (Int) -> Int = nil ?? { $0.a }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("f.map ↓{ $0.a }"),
              Example("f.filter ↓{ $0.a }"),
              Example("f.first ↓{ $0.a }"),
              Example("f.contains ↓{ $0.a }"),
              Example("f.contains(where: ↓{ $0.a })"),
              Example("f(↓{ $0.a })", configuration: Self.extendedMode),
              Example("f(a: ↓{ $0.b })", configuration: Self.extendedMode),
              Example("f(a: ↓{ a in a.b }, x)", configuration: Self.extendedMode),
              Example("f.map ↓{ a in a.b.c }"),
              Example("f.allSatisfy ↓{ (a: A) in a.b }"),
              Example("f.first ↓{ (a b: A) in b.c }"),
              Example("f.contains ↓{ $0.0.a }"),
              Example("f.compactMap ↓{ $0.a.b.c.d }"),
              Example("f.flatMap ↓{ $0.a.b }"),
              Example("let f: (Int) -> Int = ↓{ $0.bigEndian }", configuration: Self.extendedMode),
              Example("transform = ↓{ $0.a }"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("f.map { $0.a }"):
                Example("f.map(\\.a)"),
              Example(
                """
                // begin
                f.map { $0.a } // end
                """,
              ):
                Example(
                  """
                  // begin
                  f.map(\\.a) // end
                  """,
                ),
              Example("f.map({ $0.a })"):
                Example("f.map(\\.a)"),
              Example("f(a: { $0.a })", configuration: Self.extendedMode):
                Example("f(a: \\.a)"),
              Example("f({ $0.a })", configuration: Self.extendedMode):
                Example("f(\\.a)"),
              Example("let f = /* begin */ { $0.a } // end", configuration: Self.extendedMode):
                Example("let f = /* begin */ \\.a // end"),
              Example("let f = { $0.a }(b)"):
                Example("let f = { $0.a }(b)"),
              Example("let f: (Int) -> Int = ↓{ $0.bigEndian }", configuration: Self.extendedMode):
                Example("let f: (Int) -> Int = \\.bigEndian"),
              Example("f.partition ↓{ $0.a.b }"):
                Example("f.partition(by: \\.a.b)"),
              Example("f.contains ↓{ $0.a.b }"):
                Example("f.contains(where: \\.a.b)"),
              Example("f.first ↓{ element in element.a }"):
                Example("f.first(where: \\.a)"),
              Example("f.drop ↓{ element in element.a }"):
                Example("f.drop(while: \\.a)"),
              Example("f.compactMap ↓{ $0.a.b.c.d }"):
                Example("f.compactMap(\\.a.b.c.d)"),
              Example(
                "f { $0 }",
                configuration: Self.extendedModeAndIgnoreIdentity):  // no change with option enabled
                Example("f { $0 }", configuration: Self.extendedModeAndIgnoreIdentity),
              Example("f.map { $0 }", configuration: Self.ignoreIdentity):  // no change with option enabled
                Example("f.map { $0 }", configuration: Self.ignoreIdentity),
            ]
    }
    let rationale: String? = """
      Note: Swift 5 doesn't support identity key path conversions (`{ $0 }` -> `(\\.self)`) and so
      Swiftiomatic disregards `ignore_identity_closures: false` if it runs on a Swift <6 project.
      """
}
