import Foundation
import SwiftSyntax

struct TypeBodyLengthRule {
    private static let testConfig = ["warning": 2] as [String: any Sendable]
    private static let testConfigWithAllTypes = Self.testConfig.merging(
        ["excluded_types": [] as [String]],
        uniquingKeysWith: { $1 }
    )
    static let id = "type_body_length"
    static let name = "Type Body Length"
    static let summary = "Type bodies should not span too many lines"
    static var nonTriggeringExamples: [Example] {
        [
              Example("actor A {}", configuration: Self.testConfig),
              Example("class C {}", configuration: Self.testConfig),
              Example("enum E {}", configuration: Self.testConfig),
              Example("extension E {}", configuration: Self.testConfigWithAllTypes),
              Example("protocol P {}", configuration: Self.testConfigWithAllTypes),
              Example("struct S {}", configuration: Self.testConfig),
              Example(
                """
                actor A {
                    let x = 0
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                class C {
                    let x = 0
                    // comments
                    // will
                    // be
                    // ignored
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                enum E {
                    let x = 0
                    // empty lines will be ignored


                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                protocol P {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfig,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓actor A {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                ↓class C {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                ↓enum E {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfig,
              ),
              Example(
                """
                ↓extension E {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfigWithAllTypes,
              ),
              Example(
                """
                ↓protocol P {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfigWithAllTypes,
              ),
              Example(
                """
                ↓struct S {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfig,
              ),
            ]
    }
  var options = TypeBodyLengthOptions()

}

extension TypeBodyLengthRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension TypeBodyLengthRule {
  fileprivate final class Visitor: BodyLengthVisitor<OptionsType> {
    override func visitPost(_ node: ActorDeclSyntax) {
      if !configuration.excludedTypes.contains(.actor) {
        collectViolation(node)
      }
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      if !configuration.excludedTypes.contains(.class) {
        collectViolation(node)
      }
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      if !configuration.excludedTypes.contains(.enum) {
        collectViolation(node)
      }
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
      if !configuration.excludedTypes.contains(.extension) {
        collectViolation(node)
      }
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
      if !configuration.excludedTypes.contains(.protocol) {
        collectViolation(node)
      }
    }

    override func visitPost(_ node: StructDeclSyntax) {
      if !configuration.excludedTypes.contains(.struct) {
        collectViolation(node)
      }
    }

    private func collectViolation(_ node: some DeclGroupSyntax) {
      registerViolations(
        leftBrace: node.memberBlock.leftBrace,
        rightBrace: node.memberBlock.rightBrace,
        violationNode: node.introducer,
        objectName: node.introducer.text.capitalized,
      )
    }
  }
}
