struct LetVarWhitespaceConfiguration: RuleConfiguration {
    let id = "let_var_whitespace"
    let name = "Variable Declaration Whitespace"
    let summary = "Variable declarations should be separated from other statements by a blank line"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                let a = 0
                var x = 1

                var y = 2
                """,
              ),
              Example(
                """
                let a = 5

                var x = 1
                """,
              ),
              Example(
                """
                var a = 0
                """,
              ),
              Example(
                """
                let a = 1 +
                    2
                let b = 5
                """,
              ),
              Example(
                """
                var x: Int {
                    return 0
                }
                """,
              ),
              Example(
                """
                var x: Int {
                    let a = 0

                    return a
                }
                """,
              ),
              Example(
                """
                #if os(macOS)
                let a = 0

                func f() {}
                #endif
                """,
              ),
              Example(
                """
                #warning("TODO: remove it")
                let a = 0
                #warning("TODO: remove it")
                let b = 0
                """,
              ),
              Example(
                """
                #error("TODO: remove it")
                let a = 0
                """,
              ),
              Example(
                """
                @available(swift 4)
                let a = 0
                """,
              ),
              Example(
                """
                @objc
                var s: String = ""
                """,
              ),
              Example(
                """
                @objc
                func a() {}
                """,
              ),
              Example(
                """
                var x = 0
                lazy
                var y = 0
                """,
              ),
              Example(
                """
                @available(OSX, introduced: 10.6)
                @available(*, deprecated)
                var x = 0
                """,
              ),
              Example(
                """
                // sm:disable superfluous_disable_command
                // sm:disable force_cast

                let x = bar as! Bar
                """,
              ),
              Example(
                """
                @available(swift 4)
                @UserDefault("param", defaultValue: true)
                var isEnabled = true

                @Attribute
                func f() {}
                """,
              ),
              // Don't trigger on local variable declarations.
              Example(
                """
                var x: Int {
                    let a = 0
                    return a
                }
                """,
              ),
              Example(
                """
                static var test: String { /* Comment block */
                    let s = "!"
                    return "Test" + s
                }

                func f() {}
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                #"""
                @Flag(name: "name", help: "help")
                var fix = false
                @Flag(help: """
                        help
                        text
                """)
                var format = false
                @Flag(help: "help")
                var useAlternativeExcluding = false
                """#, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                let a
                ↓func x() {}
                """,
              ),
              Example(
                """
                var x = 0
                ↓@objc func f() {}
                """,
              ),
              Example(
                """
                var x = 0
                ↓@objc
                func f() {}
                """,
              ),
              Example(
                """
                @objc func f() {
                }
                ↓var x = 0
                """,
              ),
              Example(
                """
                func f() {}
                ↓@Wapper
                let isNumber = false
                @Wapper
                var isEnabled = true
                ↓func g() {}
                """,
              ),
              Example(
                """
                #if os(macOS)
                let a = 0
                ↓func f() {}
                #endif
                """,
              ),
            ]
    }
}
