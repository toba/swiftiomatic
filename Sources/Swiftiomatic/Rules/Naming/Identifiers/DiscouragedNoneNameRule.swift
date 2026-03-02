import SwiftSyntax

struct DiscouragedNoneNameRule {
    static let id = "discouraged_none_name"
    static let name = "Discouraged None Name"
    static let summary = "Enum cases and static members named `none` are discouraged as they can conflict with `Optional<T>.none`."
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              // Should not trigger unless exactly matches "none"
              Example(
                """
                enum MyEnum {
                    case nOne
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case _none
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case none_
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case none(Any)
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case nonenone
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    class var nonenone: MyClass { MyClass() }
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    static var nonenone = MyClass()
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    static let nonenone = MyClass()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    static var nonenone = MyStruct()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    static let nonenone = MyStruct()
                }
                """,
              ),

              // Should not trigger if not an enum case or static/class member
              Example(
                """
                struct MyStruct {
                    let none = MyStruct()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    var none = MyStruct()
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    let none = MyClass()
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    var none = MyClass()
                }
                """,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                enum MyEnum {
                    case ↓none
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case a, ↓none
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case ↓none, b
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case a, ↓none, b
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case a
                    case ↓none
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case ↓none
                    case b
                }
                """,
              ),
              Example(
                """
                enum MyEnum {
                    case a
                    case ↓none
                    case b
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    ↓static let none = MyClass()
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    ↓static let none: MyClass = MyClass()
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    ↓static var none: MyClass = MyClass()
                }
                """,
              ),
              Example(
                """
                class MyClass {
                    ↓class var none: MyClass { MyClass() }
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    ↓static var none = MyStruct()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    ↓static var none: MyStruct = MyStruct()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    ↓static var none = MyStruct()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    ↓static var none: MyStruct = MyStruct()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    ↓static var a = MyStruct(), none = MyStruct()
                }
                """,
              ),
              Example(
                """
                struct MyStruct {
                    ↓static var none = MyStruct(), a = MyStruct()
                }
                """,
              ),
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension DiscouragedNoneNameRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DiscouragedNoneNameRule {}

extension DiscouragedNoneNameRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: EnumCaseElementSyntax) {
      let emptyParams = node.parameterClause?.parameters.isEmpty ?? true
      if emptyParams, node.name.isNone {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: reason(type: "`case`"),
          ),
        )
      }
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      let type: String? = {
        if node.modifiers.contains(keyword: .class) {
          return "`class` member"
        }
        if node.modifiers.contains(keyword: .static) {
          return "`static` member"
        }
        return nil
      }()

      guard let type else {
        return
      }

      for binding in node.bindings {
        guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
          pattern.identifier.isNone
        else {
          continue
        }

        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: reason(type: type),
          ),
        )
        return
      }
    }

    private func reason(type: String) -> String {
      let reason =
        "Avoid naming \(type) `none` as the compiler can think you mean `Optional<T>.none`"
      let recommendation = "consider using an Optional value instead"
      return "\(reason); \(recommendation)"
    }
  }
}

extension TokenSyntax {
  fileprivate var isNone: Bool {
    tokenKind == .identifier("none") || tokenKind == .identifier("`none`")
  }
}
