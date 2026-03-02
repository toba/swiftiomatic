struct PreferConditionListConfiguration: RuleConfiguration {
    let id = "prefer_condition_list"
    let name = "Prefer Condition List"
    let summary = "Prefer a condition list over chaining conditions with '&&'"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("if a, b {}"),
              Example("guard a || b && c {}"),
              Example("if a && b || c {}"),
              Example("let result = a && b"),
              Example("repeat {} while a && b"),
              Example("if (f {}) {}"),
              Example("if f {} {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("if a ↓&& b {}"),
              Example("if a ↓&& b ↓&& c {}"),
              Example("while a ↓&& b {}"),
              Example("guard a ↓&& b {}"),
              Example("guard (a || b) ↓&& c {}"),
              Example("if a ↓&& (b && c) {}"),
              Example("guard a ↓&& b ↓&& c else {}"),
              Example("if (a ↓&& b) {}"),
              Example("if (a ↓&& f {}) {}"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("if a && b {}"):
                Example("if a, b {}"),
              Example(
                """
                if a &&
                   b {}
                """,
              ): Example(
                """
                if a,
                   b {}
                """,
              ),
              Example("guard a && b && c else {}"):
                Example("guard a, b, c else {}"),
              Example("while a && b {}"):
                Example("while a, b {}"),
              Example("if a && b || c {}"):
                Example("if a && b || c {}"),
              Example("if (a && b) {}"):
                Example("if a, b {}"),
              Example("if a && (b && c) {}"):
                Example("if a, b, c {}"),
              Example("if (a && b) && c {}"):
                Example("if a, b, c {}"),
              Example("if (a && b), c {}"):
                Example("if a, b, c {}"),
              Example("guard (a || b) ↓&& c {}"):
                Example("guard a || b, c {}"),
              Example("if a && (b || c) {}"):
                Example("if a, b || c {}"),
              Example("if (a ↓&& f {}) {}"):
                Example("if a, (f {}) {}"),
              Example("if a ↓&& (b || f {}) {}"):
                Example("if a, b || (f {}) {}"),
              Example("if a ↓&& !f {} {}"):
                Example("if a, !(f {}) {}"),
            ]
    }
    let rationale: String? = """
      Instead of chaining conditions with `&&`, use a condition list to separate conditions with commas, that is,
      use

      ```
      if a, b {}
      ```

      instead of

      ```
      if a && b {}
      ```

      Using a condition list improves readability and makes it easier to add or remove conditions in the future.
      It also allows for better formatting and alignment of conditions. All in all, it's the idiomatic way to
      write conditions in Swift.

      Since function calls with trailing closures trigger a warning in the Swift compiler when used in
      conditions, this rule makes sure to wrap such expressions in parentheses when transforming them to
      condition list elements. The scope of the parentheses is limited to the function call itself.
      """
}
