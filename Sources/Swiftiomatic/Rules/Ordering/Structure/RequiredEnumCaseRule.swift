import SwiftSyntax

/// Allows for Enums that conform to a protocol to require that a specific case be present.
///
/// This is primarily for result enums where a specific case is common but cannot be inherited due to cases not being
/// inheritable.
///
/// For example: A result enum is used to define all of the responses a client must handle from a specific service call
/// in an API.
///
/// ````
/// enum MyServiceCallResponse: String {
///     case unauthorized
///     case unknownError
///     case accountCreated
/// }
///
/// // An exhaustive switch can be used so any new scenarios added cause compile errors.
/// switch response {
///    case unauthorized:
///        ...
///    case unknownError:
///        ...
///    case accountCreated:
///        ...
/// }
/// ````
///
/// If cases could be inherited you could put all of the common ones in an enum and then inherit from that enum:
///
/// ````
/// enum MyServiceResponse: String {
///     case unauthorized
///     case unknownError
/// }
///
/// enum MyServiceCallResponse: MyServiceResponse {
///     case accountCreated
/// }
/// ````
///
/// Which would result in MyServiceCallResponse having all of the cases when compiled:
///
/// ```
/// enum MyServiceCallResponse: MyServiceResponse {
///     case unauthorized
///     case unknownError
///     case accountCreated
/// }
/// ```
///
/// Since that cannot be done this rule allows you to define cases that should be present if conforming to a protocol.
///
/// `.swiftiomatic.yaml`
/// ````
/// required_enum_case:
///   MyServiceResponse:
///     unauthorized: error
///     unknownError: error
/// ````
///
/// ````
/// protocol MyServiceResponse {}
///
/// // This will now have errors because `unauthorized` and `unknownError` are not present.
/// enum MyServiceCallResponse: String, MyServiceResponse {
///     case accountCreated
/// }
/// ````
struct RequiredEnumCaseRule {
  var options = RequiredEnumCaseOptions()

  static let configuration = RequiredEnumCaseConfiguration()
}

extension RequiredEnumCaseRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RequiredEnumCaseRule {}

extension RequiredEnumCaseRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: EnumDeclSyntax) {
      guard configuration.protocols.isNotEmpty else {
        return
      }

      let enumCases = node.enumCasesNames
      let violations = configuration.protocols
        .flatMap { type, requiredCases -> [SyntaxViolation] in
          guard node.inheritanceClause.containsInheritedType(inheritedTypes: [type])
          else {
            return []
          }

          return requiredCases.compactMap { requiredCase in
            guard !enumCases.contains(requiredCase.name) else {
              return nil
            }

            return SyntaxViolation(
              position: node.positionAfterSkippingLeadingTrivia,
              reason: "Enums conforming to \"\(type)\" must have a \"\(requiredCase.name)\" case",
              severity: requiredCase.severity,
            )
          }
        }

      self.violations.append(contentsOf: violations)
    }
  }
}

extension EnumDeclSyntax {
  fileprivate var enumCasesNames: [String] {
    memberBlock.members
      .flatMap { member -> [String] in
        guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
          return []
        }

        return enumCaseDecl.elements.map(\.name.text)
      }
  }
}
