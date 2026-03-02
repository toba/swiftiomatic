struct ArrayInitConfiguration: RuleConfiguration {
    let id = "array_init"
    let name = "Array Init"
    let summary = "Prefer using `Array(seq)` over `seq.map { $0 }` to convert a sequence into an Array"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("Array(foo)"),
              Example("foo.map { $0.0 }"),
              Example("foo.map { $1 }"),
              Example("foo.map { $0() }"),
              Example("foo.map { ((), $0) }"),
              Example("foo.map { $0! }"),
              Example("foo.map { $0! /* force unwrap */ }"),
              Example("foo.something { RouteMapper.map($0) }"),
              Example("foo.map { !$0 }"),
              Example("foo.map { /* a comment */ !$0 }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("foo.↓map({ $0 })"),
              Example("foo.↓map { $0 }"),
              Example("foo.↓map { return $0 }"),
              Example(
                """
                foo.↓map { elem in
                    elem
                }
                """,
              ),
              Example(
                """
                foo.↓map { elem in
                    return elem
                }
                """,
              ),
              Example(
                """
                foo.↓map { (elem: String) in
                    elem
                }
                """,
              ),
              Example(
                """
                foo.↓map { elem -> String in
                    elem
                }
                """,
              ),
              Example("foo.↓map { $0 /* a comment */ }"),
              Example("foo.↓map { /* a comment */ $0 }"),
            ]
    }
    let rationale: String? = """
      When converting the elements of a sequence directly into an `Array`, for clarity, prefer using the `Array` \
      constructor over calling `map`. For example

      ```
      Array(foo)
      ```

      rather than

      ```
      foo.↓map({ $0 })
      ```

      If some processing of the elements is required, then using `map` is fine. For example

      ```
      foo.map { !$0 }
      ```

      Constructs like

      ```
      enum MyError: Error {}
      let myResult: Result<String, MyError> = .success("")
      let result: Result<Any, MyError> = myResult.map { $0 }
      ```

      may be picked up as false positives by the `array_init` rule. If your codebase contains constructs like this, \
      consider using the `typesafe_array_init` analyzer rule instead.
      """
}
