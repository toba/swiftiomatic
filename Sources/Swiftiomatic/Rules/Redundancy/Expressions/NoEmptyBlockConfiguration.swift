struct NoEmptyBlockConfiguration: RuleConfiguration {
    let id = "no_empty_block"
    let name = "No Empty Block"
    let summary = "Code blocks should contain at least one statement or comment"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                func f() {
                    /* do something */
                }

                var flag = true {
                    willSet { /* do something */ }
                }
                """,
              ),

              Example(
                """
                class Apple {
                    init() { /* do something */ }

                    deinit { /* do something */ }
                }
                """,
              ),

              Example(
                """
                for _ in 0..<10 { /* do something */ }

                do {
                    /* do something */
                } catch {
                    /* do something */
                }

                func f() {
                    defer {
                        /* do something */
                    }
                    print("other code")
                }

                if flag {
                    /* do something */
                } else {
                    /* do something */
                }

                repeat { /* do something */ } while (flag)

                while i < 10 { /* do something */ }
                """,
              ),

              Example(
                """
                func f() {}

                var flag = true {
                    willSet {}
                }
                """, configuration: ["disabled_block_types": ["function_bodies"]],
              ),

              Example(
                """
                class Apple {
                    init() {}

                    deinit {}
                }
                """, configuration: ["disabled_block_types": ["initializer_bodies"]],
              ),

              Example(
                """
                for _ in 0..<10 {}

                do {
                } catch {
                }

                func f() {
                    defer {}
                    print("other code")
                }

                if flag {
                } else {
                }

                repeat {} while (flag)

                while i < 10 {}
                """, configuration: ["disabled_block_types": ["statement_blocks"]],
              ),
              Example(
                """
                f { _ in /* comment */ }
                f { _ in // comment
                }
                f { _ in
                    // comment
                }
                """,
              ),
              Example(
                """
                f {}
                {}()
                """, configuration: ["disabled_block_types": ["closure_blocks"]],
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                func f() ↓{}

                var flag = true {
                    willSet ↓{}
                }
                """,
              ),

              Example(
                """
                class Apple {
                    init() ↓{}

                    deinit ↓{}
                }
                """,
              ),

              Example(
                """
                for _ in 0..<10 ↓{}

                do ↓{
                } catch ↓{
                }

                func f() {
                    defer ↓{}
                    print("other code")
                }

                if flag ↓{
                } else ↓{
                }

                repeat ↓{} while (flag)

                while i < 10 ↓{}
                """,
              ),
              Example(
                """
                f ↓{}
                """,
              ),
              Example(
                """
                Button ↓{} label: ↓{}
                """,
              ),
            ]
    }
}
