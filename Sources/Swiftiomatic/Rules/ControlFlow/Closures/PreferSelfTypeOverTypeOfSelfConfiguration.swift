struct PreferSelfTypeOverTypeOfSelfConfiguration: RuleConfiguration {
    let id = "prefer_self_type_over_type_of_self"
    let name = "Prefer Self Type Over Type of Self"
    let summary = "Prefer `Self` over `type(of: self)` when accessing properties or calling methods"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class Foo {
                    func bar() {
                        Self.baz()
                    }
                }
                """,
              ),
              Example(
                """
                class Foo {
                    func bar() {
                        print(Self.baz)
                    }
                }
                """,
              ),
              Example(
                """
                class A {
                    func foo(param: B) {
                        type(of: param).bar()
                    }
                }
                """,
              ),
              Example(
                """
                class A {
                    func foo() {
                        print(type(of: self))
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
                class Foo {
                    func bar() {
                        ↓type(of: self).baz()
                    }
                }
                """,
              ),
              Example(
                """
                class Foo {
                    func bar() {
                        print(↓type(of: self).baz)
                    }
                }
                """,
              ),
              Example(
                """
                class Foo {
                    func bar() {
                        print(↓Swift.type(of: self).baz)
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
                class Foo {
                    func bar() {
                        ↓type(of: self).baz()
                    }
                }
                """,
              ): Example(
                """
                class Foo {
                    func bar() {
                        Self.baz()
                    }
                }
                """,
              ),
              Example(
                """
                class Foo {
                    func bar() {
                        print(↓type(of: self).baz)
                    }
                }
                """,
              ): Example(
                """
                class Foo {
                    func bar() {
                        print(Self.baz)
                    }
                }
                """,
              ),
              Example(
                """
                class Foo {
                    func bar() {
                        print(↓Swift.type(of: self).baz)
                    }
                }
                """,
              ): Example(
                """
                class Foo {
                    func bar() {
                        print(Self.baz)
                    }
                }
                """,
              ),
            ]
    }
}
