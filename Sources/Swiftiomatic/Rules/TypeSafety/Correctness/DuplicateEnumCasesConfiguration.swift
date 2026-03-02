struct DuplicateEnumCasesConfiguration: RuleConfiguration {
    let id = "duplicate_enum_cases"
    let name = "Duplicate Enum Cases"
    let summary = "Enum shouldn't contain multiple cases with the same name"
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                enum PictureImport {
                    case addImage(image: UIImage)
                    case addData(data: Data)
                }
                """,
              ),
              Example(
                """
                enum A {
                    case add(image: UIImage)
                }
                enum B {
                    case add(image: UIImage)
                }
                """,
              ),
              Example(
                """
                enum Tag: String {
                #if CONFIG_A
                    case value = "CONFIG_A"
                #elseif CONFIG_B
                    case value = "CONFIG_B"
                #else
                    case value = "CONFIG_DEFAULT"
                #endif
                }
                """,
              ),
              Example(
                """
                enum Target {
                #if os(iOS)
                  case file
                #else
                  case file(URL)
                #endif
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                enum PictureImport {
                    case ↓add(image: UIImage)
                    case addURL(url: URL)
                    case ↓add(data: Data)
                }
                """,
              )
            ]
    }
}
