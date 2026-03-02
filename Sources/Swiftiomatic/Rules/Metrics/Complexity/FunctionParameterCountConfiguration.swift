struct FunctionParameterCountConfiguration: RuleConfiguration {
    let id = "function_parameter_count"
    let name = "Function Parameter Count"
    let summary = "Number of function parameters should be low."
    var nonTriggeringExamples: [Example] {
        [
              Example("init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
              Example("init (a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
              Example("`init`(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
              Example("init?(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
              Example("init?<T>(a: T, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
              Example("init?<T: String>(a: T, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
              Example("func f2(p1: Int, p2: Int) { }"),
              Example("func f(a: Int, b: Int, c: Int, d: Int, x: Int = 42) {}"),
              Example(
                """
                func f(a: [Int], b: Int, c: Int, d: Int, f: Int) -> [Int] {
                    let s = a.flatMap { $0 as? [String: Int] } ?? []}}
                """,
              ),
              Example("override func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
              Example("↓func initialValue(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
              Example(
                "private ↓func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int = 2, g: Int) {}",
              ),
              Example(
                """
                struct Foo {
                    init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}
                    ↓func bar(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}}
                """,
              ),
            ]
    }
}
