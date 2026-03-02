struct ReduceIntoConfiguration: RuleConfiguration {
    let id = "reduce_into"
    let name = "Reduce into"
    let summary = "Prefer `reduce(into:_:)` over `reduce(_:_:)` for copy-on-write types"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                let foo = values.reduce(into: "abc") { $0 += "\\($1)" }
                """,
              ),
              Example(
                """
                values.reduce(into: Array<Int>()) { result, value in
                    result.append(value)
                }
                """,
              ),
              Example(
                """
                let rows = violations.enumerated().reduce(into: "") { rows, indexAndViolation in
                    rows.append(generateSingleRow(for: indexAndViolation.1, at: indexAndViolation.0 + 1))
                }
                """,
              ),
              Example(
                """
                zip(group, group.dropFirst()).reduce(into: []) { result, pair in
                    result.append(pair.0 + pair.1)
                }
                """,
              ),
              Example(
                """
                let foo = values.reduce(into: [String: Int]()) { result, value in
                    result["\\(value)"] = value
                }
                """,
              ),
              Example(
                """
                let foo = values.reduce(into: Dictionary<String, Int>.init()) { result, value in
                    result["\\(value)"] = value
                }
                """,
              ),
              Example(
                """
                let foo = values.reduce(into: [Int](repeating: 0, count: 10)) { result, value in
                    result.append(value)
                }
                """,
              ),
              Example(
                """
                let foo = values.reduce(MyClass()) { result, value in
                    result.handleValue(value)
                    return result
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                let bar = values.↓reduce("abc") { $0 + "\\($1)" }
                """,
              ),
              Example(
                """
                values.↓reduce(Array<Int>()) { result, value in
                    result += [value]
                }
                """,
              ),
              Example(
                """
                [1, 2, 3].↓reduce(Set<Int>()) { acc, value in
                    var result = acc
                    result.insert(value)
                    return result
                }
                """,
              ),
              Example(
                """
                let rows = violations.enumerated().↓reduce("") { rows, indexAndViolation in
                    return rows + generateSingleRow(for: indexAndViolation.1, at: indexAndViolation.0 + 1)
                }
                """,
              ),
              Example(
                """
                zip(group, group.dropFirst()).↓reduce([]) { result, pair in
                    result + [pair.0 + pair.1]
                }
                """,
              ),
              Example(
                """
                let foo = values.↓reduce([String: Int]()) { result, value in
                    var result = result
                    result["\\(value)"] = value
                    return result
                }
                """,
              ),
              Example(
                """
                let bar = values.↓reduce(Dictionary<String, Int>.init()) { result, value in
                    var result = result
                    result["\\(value)"] = value
                    return result
                }
                """,
              ),
              Example(
                """
                let bar = values.↓reduce([Int](repeating: 0, count: 10)) { result, value in
                    return result + [value]
                }
                """,
              ),
              Example(
                """
                extension Data {
                    var hexString: String {
                        return ↓reduce("") { (output, byte) -> String in
                            output + String(format: "%02x", byte)
                        }
                    }
                }
                """,
              ),
            ]
    }
}
