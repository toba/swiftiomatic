struct ControlStatementConfiguration: RuleConfiguration {
    let id = "control_statement"
    let name = "Control Statement"
    let summary = "`if`, `for`, `guard`, `switch`, `while`, and `catch` statements shouldn't unnecessarily wrap their conditionals or arguments in parentheses"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("if condition {}"),
              Example("if (a, b) == (0, 1) {}"),
              Example("if (a || b) && (c || d) {}"),
              Example("if (min...max).contains(value) {}"),
              Example("if renderGif(data) {}"),
              Example("renderGif(data)"),
              Example("guard condition else {}"),
              Example("while condition {}"),
              Example("do {} while condition {}"),
              Example("do { ; } while condition {}"),
              Example("switch foo {}"),
              Example("do {} catch let error as NSError {}"),
              Example("foo().catch(all: true) {}"),
              Example("if max(a, b) < c {}"),
              Example("switch (lhs, rhs) {}"),
              Example("if (f() { g() {} }) {}"),
              Example("if (a + f() {} == 1) {}"),
              Example("if ({ true }()) {}"),
              Example("if ({if i < 1 { true } else { false }}()) {}", isExcludedFromDocumentation: true),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓if (condition) {}"),
              Example("↓if(condition) {}"),
              Example("↓if (condition == endIndex) {}"),
              Example("↓if ((a || b) && (c || d)) {}"),
              Example("↓if ((min...max).contains(value)) {}"),
              Example("↓guard (condition) else {}"),
              Example("↓while (condition) {}"),
              Example("↓while(condition) {}"),
              Example("do { ; } ↓while(condition) {}"),
              Example("do { ; } ↓while (condition) {}"),
              Example("↓switch (foo) {}"),
              Example("do {} ↓catch(let error as NSError) {}"),
              Example("↓if (max(a, b) < c) {}"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("↓if (condition) {}"): Example("if condition {}"),
              Example("↓if(condition) {}"): Example("if condition {}"),
              Example("↓if (condition == endIndex) {}"): Example("if condition == endIndex {}"),
              Example("↓if ((a || b) && (c || d)) {}"): Example("if (a || b) && (c || d) {}"),
              Example("↓if ((min...max).contains(value)) {}"): Example(
                "if (min...max).contains(value) {}",
              ),
              Example("↓guard (condition) else {}"): Example("guard condition else {}"),
              Example("↓while (condition) {}"): Example("while condition {}"),
              Example("↓while(condition) {}"): Example("while condition {}"),
              Example("do {} ↓while (condition) {}"): Example("do {} while condition {}"),
              Example("do {} ↓while(condition) {}"): Example("do {} while condition {}"),
              Example("do { ; } ↓while(condition) {}"): Example("do { ; } while condition {}"),
              Example("do { ; } ↓while (condition) {}"): Example("do { ; } while condition {}"),
              Example("↓switch (foo) {}"): Example("switch foo {}"),
              Example("do {} ↓catch(let error as NSError) {}"): Example(
                "do {} catch let error as NSError {}",
              ),
              Example("↓if (max(a, b) < c) {}"): Example("if max(a, b) < c {}"),
              Example(
                """
                if (a),
                   ( b == 1 ) {}
                """,
              ): Example(
                """
                if a,
                   b == 1 {}
                """,
              ),
            ]
    }
}
