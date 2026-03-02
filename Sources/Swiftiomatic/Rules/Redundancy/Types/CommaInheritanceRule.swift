import Foundation
import SwiftSyntax

struct CommaInheritanceRule: SubstitutionCorrectableRule,
  SyntaxOnlyRule
{
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

  // MARK: - Rule

  func validate(file: SwiftSource) -> [RuleViolation] {
    violationRanges(in: file).map {
      RuleViolation(
        ruleType: Self.self,
        severity: options.severity,
        location: Location(file: file, stringIndex: $0.lowerBound),
      )
    }
  }

  // MARK: - SubstitutionCorrectableRule

  func substitution(for violationRange: Range<String.Index>, in _: SwiftSource)
    -> (Range<String.Index>, String)?
  {
    (violationRange, ", ")
  }

  func violationRanges(in file: SwiftSource) -> [Range<String.Index>] {
    let visitor = CommaInheritanceRuleVisitor(viewMode: .sourceAccurate)
    return visitor.walk(file: file) { visitor -> [ByteRange] in
      visitor.violationRanges
    }.compactMap {
      file.stringView.byteRangeToStringRange($0)
    }
  }
}

private final class CommaInheritanceRuleVisitor: SyntaxVisitor {
  private(set) var violationRanges: [ByteRange] = []

  override func visitPost(_ node: InheritedTypeSyntax) {
    for type in node.children(viewMode: .sourceAccurate) {
      guard let composition = type.as(CompositionTypeSyntax.self) else {
        continue
      }

      for ampersand in composition.elements.compactMap(\.ampersand) {
        let position: AbsolutePosition
        if let previousToken = ampersand.previousToken(viewMode: .sourceAccurate) {
          position = previousToken.endPositionBeforeTrailingTrivia
        } else {
          position = ampersand.position
        }

        violationRanges.append(
          ByteRange(
            location: ByteCount(position),
            length: ByteCount(ampersand.endPosition.utf8Offset - position.utf8Offset),
          ),
        )
      }
    }
  }
}
