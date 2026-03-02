struct StrictFilePrivateConfiguration: RuleConfiguration {
    let id = "strict_fileprivate"
    let name = "Strict Fileprivate"
    let summary = "`fileprivate` should be avoided"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("extension String {}"),
              Example("private extension String {}"),
              Example(
                """
                public
                    extension String {
                        var i: Int { 1 }
                    }
                """,
              ),
              Example(
                """
                    private enum E {
                        func f() {}
                    }
                """,
              ),
              Example(
                """
                    public struct S {
                        internal let i: Int
                    }
                """,
              ),
              Example(
                """
                    open class C {
                        private func f() {}
                    }
                """,
              ),
              Example(
                """
                    internal actor A {}
                """,
              ),
              Example(
                """
                    struct S1: P {
                        fileprivate let i = 2, j = 1
                    }
                    struct S2: P {
                        fileprivate var (k, l) = (1, 3)
                    }
                    protocol P {
                        var j: Int { get }
                        var l: Int { get }
                    }
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                    class C: P<Int> {
                        fileprivate func f() {}
                    }
                    protocol P<T> {
                        func f()
                    }
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                    ↓fileprivate class C {
                        ↓fileprivate func f() {}
                    }
                """,
              ),
              Example(
                """
                    ↓fileprivate extension String {
                        ↓fileprivate var isSomething: Bool { self == "something" }
                    }
                """,
              ),
              Example(
                """
                    ↓fileprivate actor A {
                        ↓fileprivate let i = 1
                    }
                """,
              ),
              Example(
                """
                    ↓fileprivate struct C {
                        ↓fileprivate(set) var myInt = 4
                    }
                """,
              ),
              Example(
                """
                    struct Outter {
                        struct Inter {
                            ↓fileprivate struct Inner {}
                        }
                    }
                """,
              ),
              Example(
                """
                    ↓fileprivate func f() {}
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
}
