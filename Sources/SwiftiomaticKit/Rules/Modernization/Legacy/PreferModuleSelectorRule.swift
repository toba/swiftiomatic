import SwiftiomaticSyntax

struct PreferModuleSelectorRule {
  static let id = "prefer_module_selector"
  static let name = "Prefer Module Selector Syntax"
  static let summary =
    "Use '::' module selector syntax instead of verbose selective imports (Swift 6.3+)"
  static let scope: Scope = .suggest

  static var nonTriggeringExamples: [Example] {
    [
      Example("import Foundation"),
      Example("import SwiftUI"),
      Example(
        """
        import Foundation
        import UIKit
        """
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("↓import struct Foundation.URL"),
      Example("↓import class UIKit.UIViewController"),
      Example("↓import func Darwin.exit"),
      Example("↓import enum Foundation.JSONDecoder.KeyDecodingStrategy"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension PreferModuleSelectorRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ViolationMessage {
  fileprivate static func selectiveImport(kind: String, path: String, selector: String) -> Self {
    "Selective 'import \(kind) \(path)' can use module selector '\(selector)'"
  }
}

extension PreferModuleSelectorRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ImportDeclSyntax) {
      guard let kindSpecifier = node.importKindSpecifier else { return }

      let pathComponents = node.path.map(\.name.text)
      guard pathComponents.count >= 2 else { return }

      let moduleName = pathComponents[0]
      let symbolPath = pathComponents.dropFirst().joined(separator: ".")
      let selectorSyntax = "\(moduleName)::\(symbolPath)"

      violations.append(
        SyntaxViolation(
          position: node.positionAfterSkippingLeadingTrivia,
          message: .selectiveImport(
            kind: kindSpecifier.text,
            path: node.path.trimmedDescription,
            selector: selectorSyntax
          ),
          confidence: .medium,
          suggestion: "Use \(selectorSyntax) at usage sites instead",
        )
      )
    }
  }
}
