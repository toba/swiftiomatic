import Foundation

struct TrailingCommaConfiguration: RuleConfiguration {
    private static let triggeringExamples: [Example] = [
        Example("let foo = [1, 2, 3↓,]"),
        Example("let foo = [1, 2, 3↓, ]"),
        Example("let foo = [1, 2, 3   ↓,]"),
        Example("let foo = [1: 2, 2: 3↓, ]"),
        Example("struct Bar {\n let foo = [1: 2, 2: 3↓, ]\n}"),
        Example("let foo = [1, 2, 3↓,] + [4, 5, 6↓,]"),
        Example("let example = [ 1,\n2↓,\n // 3,\n]"),
        Example("let foo = [\"אבג\", \"αβγ\", \"🇺🇸\"↓,]"),
        Example("class C {\n #if true\n func f() {\n let foo = [1, 2, 3↓,]\n }\n #endif\n}"),
        Example("foo([1: \"\\(error)\"↓,])"),
    ]

    private static let corrections: [Example: Example] = {
        let fixed = triggeringExamples.map { example -> Example in
            let fixedString = example.code.replacingOccurrences(of: "↓,", with: "")
            return example.with(code: fixedString)
        }
        var result: [Example: Example] = [:]
        for (triggering, correction) in zip(triggeringExamples, fixed) {
            result[triggering] = correction
        }
        return result
    }()
    let id = "trailing_comma"
    let name = "Trailing Comma"
    let summary = "Trailing commas in arrays and dictionaries should be avoided/enforced."
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let foo = [1, 2, 3]"),
              Example("let foo = []"),
              Example("let foo = [:]"),
              Example("let foo = [1: 2, 2: 3]"),
              Example("let foo = [Void]()"),
              Example("let example = [ 1,\n 2\n // 3,\n]"),
              Example("foo([1: \"\\(error)\"])"),
              Example("let foo = [Int]()"),
            ]
    }
    var triggeringExamples: [Example] {
        Self.triggeringExamples
    }
    var corrections: [Example: Example] {
        Self.corrections
    }
}
