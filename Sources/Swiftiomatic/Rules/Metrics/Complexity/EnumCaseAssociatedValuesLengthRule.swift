import SwiftSyntax

struct EnumCaseAssociatedValuesLengthRule {
    static let id = "enum_case_associated_values_count"
    static let name = "Enum Case Associated Values Count"
    static let summary = "The number of associated values in an enum case should be low."
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
            Example(
                """
                enum Employee {
                    case fullTime(name: String, retirement: Date, designation: String, contactNumber: Int)
                    case partTime(name: String, age: Int, contractEndDate: Date)
                }
                """,
            ),
            Example(
                """
                enum Barcode {
                    case upc(Int, Int, Int, Int)
                }
                """,
            ),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example(
                """
                enum Employee {
                    case ↓fullTime(name: String, retirement: Date, age: Int, designation: String, contactNumber: Int)
                    case ↓partTime(name: String, contractEndDate: Date, age: Int, designation: String, contactNumber: Int)
                }
                """,
            ),
            Example(
                """
                enum Barcode {
                    case ↓upc(Int, Int, Int, Int, Int, Int)
                }
                """,
            ),
        ]
    }

    var options = SeverityLevelsConfiguration<Self>(warning: 5, error: 6)
}

extension EnumCaseAssociatedValuesLengthRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension EnumCaseAssociatedValuesLengthRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: EnumCaseElementSyntax) {
            guard let associatedValue = node.parameterClause,
                  case let enumCaseAssociatedValueCount = associatedValue.parameters.count,
                  enumCaseAssociatedValueCount >= configuration.warning
            else {
                return
            }

            let violationSeverity: Severity
            if let errorConfig = configuration.error,
               enumCaseAssociatedValueCount >= errorConfig
            {
                violationSeverity = .error
            } else {
                violationSeverity = .warning
            }

            let reason =
                "Enum case \(node.name.text) should contain "
                    + "less than \(configuration.warning) associated values: "
                    + "currently contains \(enumCaseAssociatedValueCount)"
            violations.append(
                SyntaxViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: reason,
                    severity: violationSeverity,
                ),
            )
        }
    }
}
