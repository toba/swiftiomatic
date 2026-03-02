struct UnusedControlFlowLabelConfiguration: RuleConfiguration {
    let id = "unused_control_flow_label"
    let name = "Unused Control Flow Label"
    let summary = "Unused control flow label should be removed"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("loop: while true { break loop }"),
              Example("loop: while true { continue loop }"),
              Example("loop:\n    while true { break loop }"),
              Example("while true { break }"),
              Example("loop: for x in array { break loop }"),
              Example(
                """
                label: switch number {
                case 1: print("1")
                case 2: print("2")
                default: break label
                }
                """,
              ),
              Example(
                """
                loop: repeat {
                    if x == 10 {
                        break loop
                    }
                } while true
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓loop: while true { break }"),
              Example("↓loop: while true { break loop1 }"),
              Example("↓loop: while true { break outerLoop }"),
              Example("↓loop: for x in array { break }"),
              Example(
                """
                ↓label: switch number {
                case 1: print("1")
                case 2: print("2")
                default: break
                }
                """,
              ),
              Example(
                """
                ↓loop: repeat {
                    if x == 10 {
                        break
                    }
                } while true
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("↓loop: while true { break }"): Example("while true { break }"),
              Example("↓loop: while true { break loop1 }"): Example("while true { break loop1 }"),
              Example("↓loop: while true { break outerLoop }"): Example(
                "while true { break outerLoop }",
              ),
              Example("↓loop: for x in array { break }"): Example("for x in array { break }"),
              Example(
                """
                ↓label: switch number {
                case 1: print("1")
                case 2: print("2")
                default: break
                }
                """,
              ): Example(
                """
                switch number {
                case 1: print("1")
                case 2: print("2")
                default: break
                }
                """,
              ),
              Example(
                """
                ↓loop: repeat {
                    if x == 10 {
                        break
                    }
                } while true
                """,
              ): Example(
                """
                repeat {
                    if x == 10 {
                        break
                    }
                } while true
                """,
              ),
            ]
    }
}
