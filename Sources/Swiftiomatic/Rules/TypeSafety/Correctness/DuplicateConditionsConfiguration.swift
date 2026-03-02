struct DuplicateConditionsConfiguration: RuleConfiguration {
    let id = "duplicate_conditions"
    let name = "Duplicate Conditions"
    let summary = "Duplicate sets of conditions in the same branch instruction should be avoided"
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                if x < 5 {
                    foo()
                } else if y == "s" {
                    bar()
                }
                """,
              ),
              Example(
                """
                if x < 5 {
                    foo()
                }
                if x < 5 {
                    bar()
                }
                """,
              ),
              Example(
                """
                if x < 5, y == "s" {
                    foo()
                } else if x < 5 {
                    bar()
                }
                """,
              ),
              Example(
                """
                switch x {
                case \"a\":
                    foo()
                    bar()
                }
                """,
              ),
              Example(
                """
                switch x {
                case \"a\" where y == "s":
                    foo()
                case \"a\" where y == "t":
                    bar()
                }
                """,
              ),
              Example(
                """
                if let x = maybeAbc {
                    foo()
                } else if let x = maybePqr {
                    bar()
                }
                """,
              ),
              Example(
                """
                if let x = maybeAbc, let z = x.maybeY {
                    foo()
                } else if let x = maybePqr, let z = x.maybeY {
                    bar()
                }
                """,
              ),
              Example(
                """
                if case .p = x {
                    foo()
                } else if case .q = x {
                    bar()
                }
                """,
              ),
              Example(
                """
                if true {
                    if true { foo() }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                if ↓x < 5 {
                    foo()
                } else if y == "s" {
                    bar()
                } else if ↓x < 5 {
                    baz()
                }
                """,
              ),
              Example(
                """
                if z {
                    if ↓x < 5 {
                        foo()
                    } else if y == "s" {
                        bar()
                    } else if ↓x < 5 {
                        baz()
                    }
                }
                """,
              ),
              Example(
                """
                if ↓x < 5, y == "s" {
                    foo()
                } else if x < 10 {
                    bar()
                } else if ↓y == "s", x < 5 {
                    baz()
                }
                """,
              ),
              Example(
                """
                switch x {
                case ↓\"a\", \"b\":
                    foo()
                case \"c\", ↓\"a\":
                    bar()
                }
                """,
              ),
              Example(
                """
                switch x {
                case ↓\"a\" where y == "s":
                    foo()
                case ↓\"a\" where y == "s":
                    bar()
                }
                """,
              ),
              Example(
                """
                if ↓let xyz = maybeXyz {
                    foo()
                } else if ↓let xyz = maybeXyz {
                    bar()
                }
                """,
              ),
              Example(
                """
                if ↓let x = maybeAbc, let z = x.maybeY {
                    foo()
                } else if ↓let x = maybeAbc, let z = x.maybeY {
                    bar()
                }
                """,
              ),
              Example(
                """
                if ↓#available(macOS 10.15, *) {
                    foo()
                } else if ↓#available(macOS 10.15, *) {
                    bar()
                }
                """,
              ),
              Example(
                """
                if ↓case .p = x {
                    foo()
                } else if ↓case .p = x {
                    bar()
                }
                """,
              ),
              Example(
                """
                if ↓x < 5 {}
                else if ↓x < 5 {}
                else if ↓x < 5 {}
                """,
              ),
            ]
    }
}
