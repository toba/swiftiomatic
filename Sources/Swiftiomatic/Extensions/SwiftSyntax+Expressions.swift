import Foundation
import SwiftSyntax

extension ExprSyntax {
  /// The expression as a ``FunctionCallExprSyntax``, unwrapping a single-element tuple if needed
  ///
  /// Handles parenthesized calls like `(someFunc())` by looking through a
  /// ``TupleExprSyntax`` with exactly one element.
  var asFunctionCall: FunctionCallExprSyntax? {
    if let functionCall = `as`(FunctionCallExprSyntax.self) {
      return functionCall
    }
    if let tuple = `as`(TupleExprSyntax.self),
      let firstElement = tuple.elements.onlyElement,
      let functionCall = firstElement.expression.as(FunctionCallExprSyntax.self)
    {
      return functionCall
    }
    return nil
  }
}

extension StringLiteralExprSyntax {
  var isEmptyString: Bool {
    segments.onlyElement?.trimmedLength == .zero
  }
}

extension IntegerLiteralExprSyntax {
  var isZero: Bool {
    guard case .integerLiteral(let number) = literal.tokenKind else {
      return false
    }
    return number.isZero
  }
}

extension FloatLiteralExprSyntax {
  var isZero: Bool {
    guard case .floatLiteral(let number) = literal.tokenKind else {
      return false
    }
    return number.isZero
  }
}

extension MemberAccessExprSyntax {
  /// Whether the base expression is `self`
  var isBaseSelf: Bool {
    base?.as(DeclReferenceExprSyntax.self)?.isSelf == true
  }
}

extension DeclReferenceExprSyntax {
  var isSelf: Bool {
    baseName.text == "self"
  }
}

extension ClosureCaptureSyntax {
  /// Whether this capture binds `self`
  var capturesSelf: Bool {
    name.text == "self"
  }

  /// Whether this capture uses the `weak` specifier
  var capturesWeakly: Bool {
    specifier?.specifier.text == "weak"
  }
}

extension TypeSyntax {
  /// Whether this type is optional, either as `T?` syntax or `Optional<T>`
  var isOptionalType: Bool {
    if `is`(OptionalTypeSyntax.self) {
      return true
    }
    if let type = `as`(IdentifierTypeSyntax.self) {
      return type.name.text == "Optional" && type.genericArgumentClause?.arguments.count == 1
    }
    return false
  }
}

extension String {
  fileprivate var isZero: Bool {
    if self == "0" {  // fast path
      return true
    }

    var number = lowercased()
    for prefix in ["0x", "0o", "0b"] {
      number = number.deletingPrefix(prefix)
    }

    number = number.replacingOccurrences(of: "_", with: "")
    return Float(number) == 0
  }
}
