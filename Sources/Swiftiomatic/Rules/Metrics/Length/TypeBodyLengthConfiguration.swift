struct TypeBodyLengthConfiguration: RuleConfiguration {
    private static let testConfig = ["warning": 2] as [String: any Sendable]
    private static let testConfigWithAllTypes = Self.testConfig.merging(
        ["excluded_types": [] as [String]],
        uniquingKeysWith: { $1 }
    )
    let id = "type_body_length"
    let name = "Type Body Length"
    let summary = "Type bodies should not span too many lines"
    var nonTriggeringExamples: [Example] {
        [
              Example("actor A {}", configuration: Self.testConfig),
              Example("class C {}", configuration: Self.testConfig),
              Example("enum E {}", configuration: Self.testConfig),
              Example("extension E {}", configuration: Self.testConfigWithAllTypes),
              Example("protocol P {}", configuration: Self.testConfigWithAllTypes),
              Example("struct S {}", configuration: Self.testConfig),
              Example(
                """
                actor A {
                    let x = 0
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                class C {
                    let x = 0
                    // comments
                    // will
                    // be
                    // ignored
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                enum E {
                    let x = 0
                    // empty lines will be ignored


                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                protocol P {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfig,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓actor A {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                ↓class C {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                ↓enum E {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                ↓extension E {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfigWithAllTypes,
              ),
              Example(
                """
                ↓protocol P {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfigWithAllTypes,
              ),
              Example(
                """
                ↓struct S {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfig,
              ),
            ]
    }
}
