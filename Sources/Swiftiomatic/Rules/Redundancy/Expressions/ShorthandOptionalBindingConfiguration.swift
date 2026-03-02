struct ShorthandOptionalBindingConfiguration: RuleConfiguration {
    let id = "shorthand_optional_binding"
    let name = "Shorthand Optional Binding"
    let summary = "Use shorthand syntax for optional binding"
    let isCorrectable = true
    let isOptIn = true
    let deprecatedAliases: Set<String> = ["if_let_shadowing"]
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                if let i {}
                if let i = a {}
                guard let i = f() else {}
                if var i = i() {}
                if let i = i as? Foo {}
                guard let `self` = self else {}
                while var i { i = nil }
                """,
              ),
              Example(
                """
                if let i,
                   var i = a,
                   j > 0 {}
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                if ↓let i = i {}
                if ↓let self = self {}
                if ↓var `self` = `self` {}
                if i > 0, ↓let j = j {}
                if ↓let i = i, ↓var j = j {}
                """,
              ),
              Example(
                """
                if ↓let i = i,
                   ↓var j = j,
                   j > 0 {}
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                guard ↓let i = i else {}
                guard ↓let self = self else {}
                guard ↓var `self` = `self` else {}
                guard i > 0, ↓let j = j else {}
                guard ↓let i = i, ↓var j = j else {}
                """,
              ),
              Example(
                """
                while ↓var i = i { i = nil }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example(
                """
                if ↓let i = i {}
                """,
              ): Example(
                """
                if let i {}
                """,
              ),
              Example(
                """
                if ↓let self = self {}
                """,
              ): Example(
                """
                if let self {}
                """,
              ),
              Example(
                """
                if ↓var `self` = `self` {}
                """,
              ): Example(
                """
                if var `self` {}
                """,
              ),
              Example(
                """
                guard ↓let i = i, ↓var j = j  , ↓let k  =k else {}
                """,
              ): Example(
                """
                guard let i, var j  , let k else {}
                """,
              ),
              Example(
                """
                while j > 0, ↓var i = i   { i = nil }
                """,
              ): Example(
                """
                while j > 0, var i   { i = nil }
                """,
              ),
            ]
    }
}
