struct UnusedParameterConfiguration: RuleConfiguration {
    let id = "unused_parameter"
    let name = "Unused Parameter"
    let summary = ""
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                func f(a: Int) {
                    _ = a
                }
                """,
              ),
              Example(
                """
                func f(case: Int) {
                    _ = `case`
                }
                """,
              ),
              Example(
                """
                func f(a _: Int) {}
                """,
              ),
              Example(
                """
                func f(_: Int) {}
                """,
              ),
              Example(
                """
                func f(a: Int, b c: String) {
                    func g() {
                        _ = a
                        _ = c
                    }
                }
                """,
              ),
              Example(
                """
                func f(a: Int, c: Int) -> Int {
                    struct S {
                        let b = 1
                        func f(a: Int, b: Int = 2) -> Int { a + b }
                    }
                    return a + c
                }
                """,
              ),
              Example(
                """
                func f(a: Int?) {
                    if let a {}
                }
                """,
              ),
              Example(
                """
                func f(a: Int) {
                    let a = a
                    return a
                }
                """,
              ),
              Example(
                """
                func f(`operator`: Int) -> Int { `operator` }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                func f(↓a: Int) {}
                """,
              ),
              Example(
                """
                func f(↓a: Int, b ↓c: String) {}
                """,
              ),
              Example(
                """
                func f(↓a: Int, b ↓c: String) {
                    func g(a: Int, ↓b: Double) {
                        _ = a
                    }
                }
                """,
              ),
              Example(
                """
                struct S {
                    let a: Int

                    init(a: Int, ↓b: Int) {
                        func f(↓a: Int, b: Int) -> Int { b }
                        self.a = f(a: a, b: 0)
                    }
                }
                """,
              ),
              Example(
                """
                struct S {
                    subscript(a: Int, ↓b: Int) {
                        func f(↓a: Int, b: Int) -> Int { b }
                        return f(a: a, b: 0)
                    }
                }
                """,
              ),
              Example(
                """
                func f(↓a: Int, ↓b: Int, c: Int) -> Int {
                    struct S {
                        let b = 1
                        func f(a: Int, ↓c: Int = 2) -> Int { a + b }
                    }
                    return S().f(a: c)
                }
                """,
              ),
              Example(
                """
                func f(↓a: Int, c: String) {
                    let a = 1
                    return a + c
                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example(
                """
                func f(a: Int) {}
                """,
              ): Example(
                """
                func f(a _: Int) {}
                """,
              ),
              Example(
                """
                func f(a b: Int) {}
                """,
              ): Example(
                """
                func f(a _: Int) {}
                """,
              ),
              Example(
                """
                func f(_ a: Int) {}
                """,
              ): Example(
                """
                func f(_: Int) {}
                """,
              ),
            ]
    }
}
