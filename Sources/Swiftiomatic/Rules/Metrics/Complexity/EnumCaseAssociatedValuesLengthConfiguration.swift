struct EnumCaseAssociatedValuesLengthConfiguration: RuleConfiguration {
    let id = "enum_case_associated_values_count"
    let name = "Enum Case Associated Values Count"
    let summary = "The number of associated values in an enum case should be low."
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
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
    var triggeringExamples: [Example] {
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
}
