import SwiftSyntax

struct DuplicateEnumCasesRule {
    static let id = "duplicate_enum_cases"
    static let name = "Duplicate Enum Cases"
    static let summary = "Enum shouldn't contain multiple cases with the same name"
    static var nonTriggeringExamples: [Example] {
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
    static var triggeringExamples: [Example] {
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
  var options = SeverityOption<Self>(.error)

}

extension DuplicateEnumCasesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DuplicateEnumCasesRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: EnumDeclSyntax) {
      let enumElements = node.memberBlock.members
        .flatMap { member -> EnumCaseElementListSyntax in
          guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
            return EnumCaseElementListSyntax([])
          }

          return enumCaseDecl.elements
        }

      let elementsByName = enumElements.reduce(into: [String: [AbsolutePosition]]()) {
        elements, element in
        let name = String(element.name.text)
        elements[name, default: []].append(element.positionAfterSkippingLeadingTrivia)
      }

      let duplicatedElementPositions =
        elementsByName
        .filter { $0.value.count > 1 }
        .flatMap(\.value)

      violations.append(contentsOf: duplicatedElementPositions)
    }
  }
}
