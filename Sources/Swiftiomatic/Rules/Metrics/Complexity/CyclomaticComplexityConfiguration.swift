struct CyclomaticComplexityConfiguration: RuleConfiguration {
    let id = "cyclomatic_complexity"
    let name = "Cyclomatic Complexity"
    let summary = "Complexity of function bodies should be limited."
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                func f1() {
                    if true {
                        for _ in 1..5 { }
                    }
                    if false { }
                }
                """,
              ),
              Example(
                """
                func f(code: Int) -> Int {
                    switch code {
                    case 0: fallthrough
                    case 1: return 1
                    case 2: return 1
                    case 3: return 1
                    case 4: return 1
                    case 5: return 1
                    case 6: return 1
                    case 7: return 1
                    case 8: return 1
                    default: return 1
                    }
                }
                """,
              ),
              Example(
                """
                func f1() {
                    if true {}; if true {}; if true {}; if true {}; if true {}; if true {}
                    func f2() {
                        if true {}; if true {}; if true {}; if true {}; if true {}
                    }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓func f1() {
                    if true {
                        if true {
                            if false {}
                        }
                    }
                    if false {}
                    let i = 0
                    switch i {
                        case 1: break
                        case 2: break
                        case 3: break
                        case 4: break
                        default: break
                    }
                    for _ in 1...5 {
                        guard true else {
                            return
                        }
                    }
                }
                """,
              )
            ]
    }
}
