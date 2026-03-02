import Foundation
import SwiftSyntax

struct CommaInheritanceRule {
    static let id = "comma_inheritance"
    static let name = "Comma Inheritance Rule"
    static let summary = "Use commas to separate types in inheritance lists"
    static let isCorrectable = true
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
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
    static var triggeringExamples: [Example] {
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
    static var corrections: [Example: Example] {
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
  var options = SeverityOption<Self>(.warning)

}

extension CommaInheritanceRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: InheritedTypeSyntax) {
      for type in node.children(viewMode: .sourceAccurate) {
        guard let composition = type.as(CompositionTypeSyntax.self) else {
          continue
        }

        for ampersand in composition.elements.compactMap(\.ampersand) {
          let start: AbsolutePosition
          if let previousToken = ampersand.previousToken(viewMode: .sourceAccurate) {
            start = previousToken.endPositionBeforeTrailingTrivia
          } else {
            start = ampersand.position
          }

          let end = ampersand.endPosition
          let correction = SyntaxViolation.Correction(
            start: start,
            end: end,
            replacement: ", ",
          )

          violations.append(
            SyntaxViolation(
              position: start,
              severity: configuration.severity,
              correction: correction,
            ),
          )
        }
      }
    }
  }
}
