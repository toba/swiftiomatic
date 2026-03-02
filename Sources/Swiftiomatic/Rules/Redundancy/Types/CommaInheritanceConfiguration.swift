struct CommaInheritanceConfiguration: RuleConfiguration {
    let id = "comma_inheritance"
    let name = "Comma Inheritance Rule"
    let summary = "Use commas to separate types in inheritance lists"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("struct A: Codable, Equatable {}"),
              Example("enum B: Codable, Equatable {}"),
              Example("class C: Codable, Equatable {}"),
              Example("protocol D: Codable, Equatable {}"),
              Example("typealias E = Equatable & Codable"),
              Example("func foo<T: Equatable & Codable>(_ param: T) {}"),
              Example(
                """
                protocol G {
                    associatedtype Model: Codable, Equatable
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("struct A: Codable↓ & Equatable {}"),
              Example("struct A: Codable↓  & Equatable {}"),
              Example("struct A: Codable↓&Equatable {}"),
              Example("struct A: Codable↓& Equatable {}"),
              Example("enum B: Codable↓ & Equatable {}"),
              Example("class C: Codable↓ & Equatable {}"),
              Example("protocol D: Codable↓ & Equatable {}"),
              Example(
                """
                protocol G {
                    associatedtype Model: Codable↓ & Equatable
                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("struct A: Codable↓ & Equatable {}"): Example(
                "struct A: Codable, Equatable {}",
              ),
              Example("struct A: Codable↓  & Equatable {}"): Example(
                "struct A: Codable, Equatable {}",
              ),
              Example("struct A: Codable↓&Equatable {}"): Example("struct A: Codable, Equatable {}"),
              Example("struct A: Codable↓& Equatable {}"): Example("struct A: Codable, Equatable {}"),
              Example("enum B: Codable↓ & Equatable {}"): Example("enum B: Codable, Equatable {}"),
              Example("class C: Codable↓ & Equatable {}"): Example("class C: Codable, Equatable {}"),
              Example("protocol D: Codable↓ & Equatable {}"): Example(
                "protocol D: Codable, Equatable {}",
              ),
              Example(
                """
                protocol G {
                    associatedtype Model: Codable↓ & Equatable
                }
                """,
              ): Example(
                """
                protocol G {
                    associatedtype Model: Codable, Equatable
                }
                """,
              ),
            ]
    }
}
