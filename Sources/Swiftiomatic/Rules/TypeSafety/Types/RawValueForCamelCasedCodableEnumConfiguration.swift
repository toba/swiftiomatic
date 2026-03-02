struct RawValueForCamelCasedCodableEnumConfiguration: RuleConfiguration {
    let id = "raw_value_for_camel_cased_codable_enum"
    let name = "Raw Value for Camel Cased Codable Enum"
    let summary = "Camel cased cases of Codable String enums should have raw values"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                enum Numbers: Codable {
                  case int(Int)
                  case short(Int16)
                }
                """,
              ),
              Example(
                """
                enum Numbers: Int, Codable {
                  case one = 1
                  case two = 2
                }
                """,
              ),
              Example(
                """
                enum Numbers: Double, Codable {
                  case one = 1.1
                  case two = 2.2
                }
                """,
              ),
              Example(
                """
                enum Numbers: String, Codable {
                  case one = "one"
                  case two = "two"
                }
                """,
              ),
              Example(
                """
                enum Status: String, Codable {
                    case OK, ACCEPTABLE
                }
                """,
              ),
              Example(
                """
                enum Status: String, Codable {
                    case ok
                    case maybeAcceptable = "maybe_acceptable"
                }
                """,
              ),
              Example(
                """
                enum Status: String {
                    case ok
                    case notAcceptable
                    case maybeAcceptable = "maybe_acceptable"
                }
                """,
              ),
              Example(
                """
                enum Status: Int, Codable {
                    case ok
                    case notAcceptable
                    case maybeAcceptable = -1
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                enum Status: String, Codable {
                    case ok
                    case ↓notAcceptable
                    case maybeAcceptable = "maybe_acceptable"
                }
                """,
              ),
              Example(
                """
                enum Status: String, Decodable {
                   case ok
                   case ↓notAcceptable
                   case maybeAcceptable = "maybe_acceptable"
                }
                """,
              ),
              Example(
                """
                enum Status: String, Encodable {
                   case ok
                   case ↓notAcceptable
                   case maybeAcceptable = "maybe_acceptable"
                }
                """,
              ),
              Example(
                """
                enum Status: String, Codable {
                    case ok
                    case ↓notAcceptable
                    case maybeAcceptable = "maybe_acceptable"
                }
                """,
              ),
            ]
    }
}
