struct EmptyCountConfiguration: RuleConfiguration {
    let id = "empty_count"
    let name = "Empty Count"
    let summary = "Prefer checking `isEmpty` over comparing `count` to zero"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("var count = 0"),
              Example("[Int]().isEmpty"),
              Example("[Int]().count > 1"),
              Example("[Int]().count == 1"),
              Example("[Int]().count == 0xff"),
              Example("[Int]().count == 0b01"),
              Example("[Int]().count == 0o07"),
              Example("discount == 0"),
              Example("order.discount == 0"),
              Example("let rule = #Rule(Tips.Event(id: \"someTips\")) { $0.donations.count == 0 }"),
              Example("#Rule(param1: \"param1\")", isExcludedFromDocumentation: true),
              Example("func isEmpty(count: Int) -> Bool { count == 0 }"),
              Example(
                """
                var isEmpty: Bool {
                    let count = 0
                    return count == 0
                }
                """,
              ),
              Example("{ count in count == 0 }()"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("[Int]().↓count == 0"),
              Example("0 == [Int]().↓count"),
              Example("[Int]().↓count==0"),
              Example("[Int]().↓count > 0"),
              Example("[Int]().↓count != 0"),
              Example("[Int]().↓count == 0x0"),
              Example("[Int]().↓count == 0x00_00"),
              Example("[Int]().↓count == 0b00"),
              Example("[Int]().↓count == 0o00"),
              Example("↓count == 0"),
              Example("#ExampleMacro { $0.list.↓count == 0 }"),
              Example("#Rule { $0.donations.↓count == 0 }", isExcludedFromDocumentation: true),
              Example(
                "#Rule(param1: \"param1\", param2: \"param2\") { $0.donations.↓count == 0 }",
                isExcludedFromDocumentation: true,
              ),
              Example(
                "#Rule(param1: \"param1\") { $0.donations.↓count == 0 } closure2: { doSomething() }",
                isExcludedFromDocumentation: true,
              ),
              Example(
                "#Rule(param1: \"param1\") { return $0.donations.↓count == 0 }",
                isExcludedFromDocumentation: true,
              ),
              Example(
                """
                #Rule(param1: "param1") {
                    doSomething()
                    return $0.donations.↓count == 0
                }
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                extension E {
                    var isEmpty: Bool { ↓count == 0 }
                }
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                struct S {
                    var isEmpty: Bool { ↓count == 0 }
                }
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("[].↓count == 0"):
                Example("[].isEmpty"),
              Example("0 == [].↓count"):
                Example("[].isEmpty"),
              Example("[Int]().↓count == 0"):
                Example("[Int]().isEmpty"),
              Example("0 == [Int]().↓count"):
                Example("[Int]().isEmpty"),
              Example("[Int]().↓count==0"):
                Example("[Int]().isEmpty"),
              Example("[Int]().↓count > 0"):
                Example("![Int]().isEmpty"),
              Example("[Int]().↓count != 0"):
                Example("![Int]().isEmpty"),
              Example("[Int]().↓count == 0x0"):
                Example("[Int]().isEmpty"),
              Example("[Int]().↓count == 0x00_00"):
                Example("[Int]().isEmpty"),
              Example("[Int]().↓count == 0b00"):
                Example("[Int]().isEmpty"),
              Example("[Int]().↓count == 0o00"):
                Example("[Int]().isEmpty"),
              Example("↓count == 0"):
                Example("isEmpty"),
              Example("↓count == 0 && [Int]().↓count == 0o00"):
                Example("isEmpty && [Int]().isEmpty"),
              Example(
                "[Int]().count != 3 && [Int]().↓count != 0 || ↓count == 0 && [Int]().count > 2",
              ):
                Example("[Int]().count != 3 && ![Int]().isEmpty || isEmpty && [Int]().count > 2"),
              Example("#ExampleMacro { $0.list.↓count == 0 }"):
                Example("#ExampleMacro { $0.list.isEmpty }"),
              Example("#Rule(param1: \"param1\") { return $0.donations.↓count == 0 }"):
                Example("#Rule(param1: \"param1\") { return $0.donations.isEmpty }"),
            ]
    }
}
