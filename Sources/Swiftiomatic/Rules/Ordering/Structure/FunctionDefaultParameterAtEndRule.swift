import SwiftSyntax

struct FunctionDefaultParameterAtEndRule {
  var options = FunctionDefaultParameterAtEndOptions()

  static let configuration = FunctionDefaultParameterAtEndConfiguration()
}

extension FunctionDefaultParameterAtEndRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension FunctionDefaultParameterAtEndRule {}

extension FunctionDefaultParameterAtEndRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      if !node.modifiers.contains(keyword: .override) {
        collectViolations(for: node.signature)
      }
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      if !node.modifiers.contains(keyword: .override) {
        collectViolations(for: node.signature)
      }
    }

    private func collectViolations(for signature: FunctionSignatureSyntax) {
      let numberOfParameters = signature.parameterClause.parameters.count
      if numberOfParameters < 2 {
        return
      }
      var previousWithDefault = true
      for (index, param) in signature.parameterClause.parameters.reversed().enumerated() {
        if param.isClosure {
          continue
        }
        let hasDefault = param.defaultValue != nil
        if !previousWithDefault, hasDefault {
          if index + 1 == numberOfParameters,
            param.isInheritedIsolation,
            configuration.ignoreFirstIsolationInheritanceParameter
          {
            break  // It's the last element anyway.
          }
          violations.append(param.positionAfterSkippingLeadingTrivia)
        }
        previousWithDefault = hasDefault
      }
    }
  }
}

extension FunctionParameterSyntax {
  fileprivate var isClosure: Bool {
    isEscaping || type.isFunctionType
  }

  fileprivate var isEscaping: Bool {
    type.as(AttributedTypeSyntax.self)?.attributes.contains(attributeNamed: "escaping") == true
  }

  fileprivate var isInheritedIsolation: Bool {
    defaultValue?.value.as(MacroExpansionExprSyntax.self)?.macroName.text == "isolation"
  }
}

extension TypeSyntax {
  fileprivate var isFunctionType: Bool {
    if `is`(FunctionTypeSyntax.self) {
      true
    } else if let optionalType = `as`(OptionalTypeSyntax.self) {
      optionalType.wrappedType.isFunctionType
    } else if let tupleType = `as`(TupleTypeSyntax.self) {
      tupleType.elements.onlyElement?.type.isFunctionType == true
    } else if let attributedType = `as`(AttributedTypeSyntax.self) {
      attributedType.baseType.isFunctionType
    } else {
      false
    }
  }
}
