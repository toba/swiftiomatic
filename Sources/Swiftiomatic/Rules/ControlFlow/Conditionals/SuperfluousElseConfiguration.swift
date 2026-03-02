struct SuperfluousElseConfiguration: RuleConfiguration {
    let id = "superfluous_else"
    let name = "Superfluous Else"
    let summary = "Else branches should be avoided when the previous if-block exits the current scope"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                if i > 0 {
                    // comment
                } else if i < 12 {
                    return 2
                } else {
                    return 3
                }
                """,
              ),
              Example(
                """
                if i > 0 {
                    let a = 1
                    if a > 1 {
                        // comment
                    } else {
                        return 1
                    }
                    // comment
                } else {
                    return 3
                }
                """,
              ),
              Example(
                """
                if i > 0 {
                    if a > 1 {
                        return 1
                    }
                } else {
                    return 3
                }
                """,
              ),
              Example(
                """
                if i > 0 {
                    if a > 1 {
                        if a > 1 {
                            // comment
                        } else {
                            return 1
                        }
                    }
                } else {
                    return 3
                }
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                for i in list {
                    if i > 12 {
                        // Do nothing
                    } else {
                        continue
                    }
                    if i > 14 {
                        // Do nothing
                    } else if i > 13 {
                        break
                    }
                }
                """,
              ),
              Example(
                """
                if #available(iOS 13, *) {
                    return
                } else {
                    deprecatedFunction()
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                if i > 0 {
                    return 1
                    // comment
                } ↓else {
                    return 2
                }
                """,
              ),
              Example(
                """
                if i > 0 {
                    return 1
                } ↓else if i < 12 {
                    return 2
                } ↓else if i > 18 {
                    return 3
                }
                """,
              ),
              Example(
                """
                if i > 0 {
                    if i < 12 {
                        return 5
                    } ↓else {
                        if i > 11 {
                            return 6
                        } ↓else {
                            return 7
                        }
                    }
                } ↓else if i < 12 {
                    return 2
                } ↓else if i < 24 {
                    return 8
                } ↓else {
                    return 3
                }
                """,
              ),
              Example(
                """
                for i in list {
                    if i > 13 {
                        return
                    } ↓else if i > 12 {
                        continue
                    } ↓else if i > 11 {
                        break
                    } ↓else {
                        throw error
                    }
                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example(
                """
                func f() -> Int {
                    if i > 0 {
                        return 1
                        // comment
                    } ↓else {
                        // another comment
                        return 2
                        // yet another comment
                    }
                }
                """,
              ): Example(
                """
                func f() -> Int {
                    if i > 0 {
                        return 1
                        // comment
                    }
                    // another comment
                    return 2
                    // yet another comment
                }
                """,
              ),
              Example(
                """
                func f() -> Int {
                    if i > 0 {
                        return 1
                        // comment
                    } ↓else if i < 10 {
                        return 2
                    } ↓else {
                        return 3
                    }
                }
                """,
              ): Example(
                """
                func f() -> Int {
                    if i > 0 {
                        return 1
                        // comment
                    }
                    if i < 10 {
                        return 2
                    }
                    return 3
                }
                """,
              ),
              Example(
                """
                func f() -> Int {

                    if i > 0 {
                        return 1
                        // comment
                    } ↓else if i < 10 {
                        // another comment
                        return 2
                    }
                }
                """,
              ): Example(
                """
                func f() -> Int {

                    if i > 0 {
                        return 1
                        // comment
                    }
                    if i < 10 {
                        // another comment
                        return 2
                    }
                }
                """,
              ),
              Example(
                """
                {
                    if i > 0 {
                        return 1
                    } ↓else {
                        return 2
                    }
                }()
                """,
              ): Example(
                """
                {
                    if i > 0 {
                        return 1
                    }
                    return 2
                }()
                """,
              ),
              Example(
                """
                for i in list {
                    if i > 13 {
                        return
                    } ↓else if i > 12 {
                        continue // continue with next index
                    } ↓else if i > 11 {
                        break
                        // end of loop
                    } ↓else if i > 10 {
                        // Some error
                        throw error
                    } ↓else {

                    }
                }
                """,
              ): Example(
                """
                for i in list {
                    if i > 13 {
                        return
                    }
                    if i > 12 {
                        continue // continue with next index
                    }
                    if i > 11 {
                        break
                        // end of loop
                    }
                    if i > 10 {
                        // Some error
                        throw error
                    }
                }
                """,
              ),
            ]
    }
}
