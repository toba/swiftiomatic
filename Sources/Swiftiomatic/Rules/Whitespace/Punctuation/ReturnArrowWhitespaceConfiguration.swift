struct ReturnArrowWhitespaceConfiguration: RuleConfiguration {
    let id = "return_arrow_whitespace"
    let name = "Returning Whitespace"
    let summary = "Return arrow and return type should be separated by a single space or on a separate line"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("func abc() -> Int {}"),
              Example("func abc() -> [Int] {}"),
              Example("func abc() -> (Int, Int) {}"),
              Example("var abc = {(param: Int) -> Void in }"),
              Example("func abc() ->\n    Int {}"),
              Example("func abc()\n    -> Int {}"),
              Example(
                """
                func reallyLongFunctionMethods<T>(withParam1: Int, param2: String, param3: Bool) where T: AGenericConstraint
                    -> Int {
                    return 1
                }
                """,
              ),
              Example("typealias SuccessBlock = ((Data) -> Void)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("func abc()↓->Int {}"),
              Example("func abc()↓->[Int] {}"),
              Example("func abc()↓->(Int, Int) {}"),
              Example("func abc()↓-> Int {}"),
              Example("func abc()↓->   Int {}"),
              Example("func abc()↓ ->Int {}"),
              Example("func abc()↓  ->  Int {}"),
              Example("var abc = {(param: Int)↓ ->Bool in }"),
              Example("var abc = {(param: Int)↓->Bool in }"),
              Example("typealias SuccessBlock = ((Data)↓->Void)"),
              Example("func abc()\n  ↓->  Int {}"),
              Example("func abc()\n ↓->  Int {}"),
              Example("func abc()↓  ->\n  Int {}"),
              Example("func abc()↓  ->\nInt {}"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("func abc()↓->Int {}"): Example("func abc() -> Int {}"),
              Example("func abc()↓-> Int {}"): Example("func abc() -> Int {}"),
              Example("func abc()↓ ->Int {}"): Example("func abc() -> Int {}"),
              Example("func abc()↓  ->  Int {}"): Example("func abc() -> Int {}"),
              Example("func abc()\n  ↓->  Int {}"): Example("func abc()\n  -> Int {}"),
              Example("func abc()\n ↓->  Int {}"): Example("func abc()\n -> Int {}"),
              Example("func abc()↓  ->\n  Int {}"): Example("func abc() ->\n  Int {}"),
              Example("func abc()↓  ->\nInt {}"): Example("func abc() ->\nInt {}"),
            ]
    }
}
