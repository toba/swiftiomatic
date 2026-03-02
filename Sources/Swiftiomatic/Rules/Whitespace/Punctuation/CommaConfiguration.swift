struct CommaConfiguration: RuleConfiguration {
    let id = "comma"
    let name = "Comma Spacing"
    let summary = "There should be no space before and one after any comma"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("func abc(a: String, b: String) { }"),
              Example("abc(a: \"string\", b: \"string\""),
              Example("enum a { case a, b, c }"),
              Example("func abc(\n  a: String,  // comment\n  bcd: String // comment\n) {\n}"),
              Example("func abc(\n  a: String,\n  bcd: String\n) {\n}"),
              Example("#imageLiteral(resourceName: \"foo,bar,baz\")"),
              Example(
                """
                kvcStringBuffer.advanced(by: rootKVCLength)
                  .storeBytes(of: 0x2E /* '.' */, as: CChar.self)
                """,
              ),
              Example(
                """
                public indirect enum ExpectationMessage {
                  /// appends after an existing message ("<expectation> (use beNil() to match nils)")
                  case appends(ExpectationMessage, /* Appended Message */ String)
                }
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("func abc(a: String↓ ,b: String) { }"),
              Example("func abc(a: String↓ ,b: String↓ ,c: String↓ ,d: String) { }"),
              Example("abc(a: \"string\"↓,b: \"string\""),
              Example("enum a { case a↓ ,b }"),
              Example("let result = plus(\n    first: 3↓ , // #683\n    second: 4\n)"),
              Example(
                """
                Foo(
                  parameter: a.b.c,
                  tag: a.d,
                  value: a.identifier.flatMap { Int64($0) }↓ ,
                  reason: Self.abcd()
                )
                """,
              ),
              Example(
                """
                return Foo(bar: .baz, title: fuzz,
                          message: My.Custom.message↓ ,
                          another: parameter, doIt: true,
                          alignment: .center)
                """,
              ),
              Example(#"Logger.logError("Hat is too large"↓,  info: [])"#),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("func abc(a: String↓,b: String) {}"): Example(
                "func abc(a: String, b: String) {}",
              ),
              Example("abc(a: \"string\"↓,b: \"string\""): Example(
                "abc(a: \"string\", b: \"string\"",
              ),
              Example("abc(a: \"string\"↓  ,  b: \"string\""): Example(
                "abc(a: \"string\", b: \"string\"",
              ),
              Example("enum a { case a↓  ,b }"): Example("enum a { case a, b }"),
              Example("let a = [1↓,1]\nlet b = 1\nf(1, b)"): Example(
                "let a = [1, 1]\nlet b = 1\nf(1, b)",
              ),
              Example("let a = [1↓,1↓,1↓,1]"): Example("let a = [1, 1, 1, 1]"),
              Example(
                """
                Foo(
                  parameter: a.b.c,
                  tag: a.d,
                  value: a.identifier.flatMap { Int64($0) }↓ ,
                  reason: Self.abcd()
                )
                """,
              ): Example(
                """
                Foo(
                  parameter: a.b.c,
                  tag: a.d,
                  value: a.identifier.flatMap { Int64($0) },
                  reason: Self.abcd()
                )
                """,
              ),
              Example(
                """
                return Foo(bar: .baz, title: fuzz,
                          message: My.Custom.message↓ ,
                          another: parameter, doIt: true,
                          alignment: .center)
                """,
              ): Example(
                """
                return Foo(bar: .baz, title: fuzz,
                          message: My.Custom.message,
                          another: parameter, doIt: true,
                          alignment: .center)
                """,
              ),
              Example(#"Logger.logError("Hat is too large"↓,  info: [])"#):
                Example(#"Logger.logError("Hat is too large", info: [])"#),
            ]
    }
}
