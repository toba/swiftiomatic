struct TrailingClosureConfiguration: RuleConfiguration {
    private static let onlySingleMutedConfig = ["only_single_muted_parameter": true]
    let id = "trailing_closure"
    let name = "Trailing Closure"
    let summary = "Trailing closure syntax should be used whenever possible"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("foo.map { $0 + 1 }"),
              Example("foo.bar()"),
              Example("foo.reduce(0) { $0 + 1 }"),
              Example("if let foo = bar.map({ $0 + 1 }) { }"),
              Example("foo.something(param1: { $0 }, param2: { $0 + 1 })"),
              Example("offsets.sorted { $0.offset < $1.offset }"),
              Example("foo.something({ return 1 }())"),
              Example("foo.something({ return $0 }(1))"),
              Example("foo.something(0, { return 1 }())"),
              Example("for x in list.filter({ $0.isValid }) {}"),
              Example("if list.allSatisfy({ $0.isValid }) {}"),
              Example("foo(param1: 1, param2: { _ in true }, param3: 0)"),
              Example("foo(param1: 1, param2: { _ in true }) { $0 + 1 }"),
              Example("foo(param1: { _ in false }, param2: { _ in true })"),
              Example("foo(param1: { _ in false }, param2: { _ in true }, param3: { _ in false })"),
              Example(
                """
                if f({ true }), g({ true }) {
                    print("Hello")
                }
                """,
              ),
              Example(
                """
                for i in h({ [1,2,3] }) {
                    print(i)
                }
                """,
              ),
              Example("foo.reduce(0, combine: { $0 + 1 })", configuration: Self.onlySingleMutedConfig),
              Example(
                "offsets.sorted(by: { $0.offset < $1.offset })",
                configuration: Self.onlySingleMutedConfig,
              ),
              Example("foo.something(0, { $0 + 1 })", configuration: Self.onlySingleMutedConfig),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("foo.map(↓{ $0 + 1 })"),
              Example("foo.reduce(0, combine: ↓{ $0 + 1 })"),
              Example("offsets.sorted(by: ↓{ $0.offset < $1.offset })"),
              Example("foo.something(0, ↓{ $0 + 1 })"),
              Example("foo.something(param1: { _ in true }, param2: 0, param3: ↓{ _ in false })"),
              Example(
                """
                for n in list {
                    n.forEach(↓{ print($0) })
                }
                """, isExcludedFromDocumentation: true,
              ),
              Example("foo.map(↓{ $0 + 1 })", configuration: Self.onlySingleMutedConfig),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("foo.map(↓{ $0 + 1 })"):
                Example("foo.map { $0 + 1 }"),
              Example("foo.reduce(0, combine: ↓{ $0 + 1 })"):
                Example("foo.reduce(0) { $0 + 1 }"),
              Example("offsets.sorted(by: ↓{ $0.offset < $1.offset })"):
                Example("offsets.sorted { $0.offset < $1.offset }"),
              Example("foo.something(0, ↓{ $0 + 1 })"):
                Example("foo.something(0) { $0 + 1 }"),
              Example("foo.something(param1: { _ in true }, param2: 0, param3: ↓{ _ in false })"):
                Example("foo.something(param1: { _ in true }, param2: 0) { _ in false }"),
              Example("f(a: ↓{ g(b: ↓{ 1 }) })"):
                Example("f { g { 1 }}"),
              Example(
                """
                for n in list {
                    n.forEach(↓{ print($0) })
                }
                """,
              ): Example(
                """
                for n in list {
                    n.forEach { print($0) }
                }
                """,
              ),
              Example(
                """
                f(a: 1,
                b: 2,
                c: { 3 })
                """,
              ): Example(
                """
                f(a: 1,
                b: 2) { 3 }
                """,
              ),
              Example("foo.map(↓{ $0 + 1 })", configuration: Self.onlySingleMutedConfig):
                Example("foo.map { $0 + 1 }", configuration: Self.onlySingleMutedConfig),
              Example("f(↓{ g(↓{ 1 }) })", configuration: Self.onlySingleMutedConfig):
                Example("f { g { 1 }}", configuration: Self.onlySingleMutedConfig),
              Example(
                """
                for n in list {
                    n.forEach(↓{ print($0) })
                }
                """, configuration: Self.onlySingleMutedConfig,
              ): Example(
                """
                for n in list {
                    n.forEach { print($0) }
                }
                """,
              ),
              Example(
                """
                f(a: 1, // comment
                b: 2, /* comment */ c: { 3 })
                """,
              ): Example(
                """
                f(a: 1, // comment
                b: 2) /* comment */ { 3 }
                """,
              ),
              Example(
                """
                f(a: 2, c: /* comment */ { 3 } /* comment */)
                """,
              ): Example(
                """
                f(a: 2) /* comment */ { 3 } /* comment */
                """,
              ),
              Example(
                """
                f(a: 2, /* comment */ c /* comment */ : /* comment */ { 3 } /* comment */)
                """,
              ): Example(
                """
                f(a: 2) /* comment */ { 3 } /* comment */
                """,
              ),
              Example(
                """
                f(a: 2, /* comment1 */ c /* comment2 */ : /* comment3 */ { 3 } /* comment4 */)
                """,
              ): Example(
                """
                f(a: 2) /* comment1 */ /* comment2 */ /* comment3 */ { 3 } /* comment4 */
                """,
              ),
              Example(
                """
                let dataSource = RxTableViewSectionedReloadDataSource(
                    configureCell: { cell in // sm:disable:this trailing_closure
                        return cell
                    }
                )
                """,
              ): Example(
                """
                let dataSource = RxTableViewSectionedReloadDataSource(
                    configureCell: { cell in // sm:disable:this trailing_closure
                        return cell
                    }
                )
                """,
              ),
            ]
    }
}
