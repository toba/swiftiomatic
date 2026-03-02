struct FunctionBodyLengthConfiguration: RuleConfiguration {
    private static let testConfig = ["warning": 2]
    let id = "function_body_length"
    let name = "Function Body Length"
    let summary = "Function bodies should not span too many lines"
    var nonTriggeringExamples: [Example] {
        [
              Example("func f() {}", configuration: Self.testConfig),
              Example(
                """
                func f() {
                    let x = 0
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                func f() {
                    let x = 0
                    let y = 1
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                func f() {
                    let x = 0
                    // comments
                    // will
                    // be
                    // ignored
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                    func f() {
                        let x = 0
                        // empty lines will be ignored


                    }
                """, configuration: Self.testConfig,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓func f() {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                class C {
                    ↓deinit {
                        let x = 0
                        let y = 1
                        let z = 2
                    }
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                class C {
                    ↓init() {
                        let x = 0
                        let y = 1
                        let z = 2
                    }
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                class C {
                    ↓subscript() -> Int {
                        let x = 0
                        let y = 1
                        return x + y
                    }
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                struct S {
                    subscript() -> Int {
                        ↓get {
                            let x = 0
                            let y = 1
                            return x + y
                        }
                        ↓set {
                            let x = 0
                            let y = 1
                            let z = 2
                        }
                        ↓willSet {
                            let x = 0
                            let y = 1
                            let z = 2
                        }
                    }
                }
                """, configuration: Self.testConfig,
              ),
            ]
    }
}
