import Foundation
import SwiftSyntax

struct TypesafeArrayInitRule: Rule {
  static let id = "typesafe_array_init"
  static let name = "Type-safe Array Init"
  static let summary =
    "Prefer using `Array(seq)` over `seq.map { $0 }` to convert a sequence into an Array"
  static let isCorrectable = true
  static let isOptIn = true
  static let requiresSourceKit = true
  static let requiresCompilerArguments = true
  static let requiresFileOnDisk = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        enum MyError: Error {}
        let myResult: Result<String, MyError> = .success("")
        let result: Result<Any, MyError> = myResult.map { $0 }
        """,
      ),
      Example(
        """
        struct IntArray {
            let elements = [1, 2, 3]
            func map<T>(_ transformer: (Int) throws -> T) rethrows -> [T] {
                try elements.map(transformer)
            }
        }
        let ints = IntArray()
        let intsCopy = ints.map { $0 }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        func f<Seq: Sequence>(s: Seq) -> [Seq.Element] {
            s.↓map({ $0 })
        }
        """,
      ),
      Example(
        """
        func f(array: [Int]) -> [Int] {
            array.↓map { $0 }
        }
        """,
      ),
      Example(
        """
        let myInts = [1, 2, 3].↓map { return $0 }
        """,
      ),
      Example(
        """
        struct Generator: Sequence, IteratorProtocol {
            func next() -> Int? { nil }
        }
        let array = Generator().↓map { i in i }
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)

  private static let mapTypePatterns = [
    regex(
      """
      \\Q<Self, T where Self : \\E(?:Sequence|Collection)> \
      \\Q(Self) -> ((Self.Element) throws -> T) throws -> [T]\\E
      """,
    ),
    regex(
      """
      \\Q<Self, T, E where Self : \\E(?:Sequence|Collection), \
      \\QE : Error> (Self) -> ((Self.Element) throws(E) -> T) throws(E) -> [T]\\E
      """,
    ),
  ]

  func validate(file: SwiftSource, compilerArguments: [String]) -> [RuleViolation] {
    guard let filePath = file.path else {
      return []
    }
    guard compilerArguments.isNotEmpty else {
      SwiftiomaticError.missingCompilerArguments(path: file.path, ruleID: Self.identifier)
        .print()
      return []
    }
    return findIdentityMapViolations(in: file)
      .filter { violation in
        guard let offset = getOffset(in: file, at: violation.location) else {
          return false
        }
        let cursorInfo = Request.cursorInfoWithoutSymbolGraph(
          file: filePath, offset: offset, arguments: compilerArguments,
        )
        guard let request = try? cursorInfo.sendIfNotDisabled() else {
          return false
        }
        return pointsToSystemMapType(pointee: request)
      }.map { RuleViolation(ruleType: Self.self, location: $0.location) }
  }

  private func pointsToSystemMapType(pointee: [String: SourceKitValue]) -> Bool {
    if pointee["key.is_system"]?.boolValue == true,
      pointee["key.name"]?.stringValue == "map(_:)",
      let typeName = pointee["key.typename"]?.stringValue
    {
      return Self.mapTypePatterns.contains { pattern in
        pattern.hasMatch(in: typeName, range: typeName.fullNSRange)
      }
    }
    return false
  }

  private func getOffset(in file: SwiftSource, at location: Location) -> ByteCount? {
    guard let line = location.line, let offset = location.column else {
      return nil
    }
    return file.stringView.byteOffset(forLine: Int64(line), bytePosition: Int64(offset))
  }

  /// Syntactic detection of `.map { $0 }` identity transforms (inlined from former ArrayInitRule)
  private func findIdentityMapViolations(in file: SwiftSource) -> [RuleViolation] {
    let visitor = IdentityMapVisitor(configuration: options, file: file)
    let violations = visitor.walk(tree: file.syntaxTree, handler: \.violations)
    return violations.map { violation in
      RuleViolation(
        ruleType: Self.self,
        severity: options.severity,
        location: Location(file: file, position: violation.position),
        confidence: .medium,
      )
    }
  }
}

extension TypesafeArrayInitRule {
  fileprivate final class IdentityMapVisitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
        memberAccess.declName.baseName.text == "map"
      else { return }

      let closure: ClosureExprSyntax
      if let arg = node.arguments.first?.expression.as(ClosureExprSyntax.self),
        node.arguments.count == 1
      {
        closure = arg
      } else if node.arguments.isEmpty, let trailing = node.trailingClosure {
        closure = trailing
      } else {
        return
      }

      guard let onlyStmt = closure.statements.first,
        closure.statements.count == 1
      else { return }

      let paramName = closure.signature?.singleInputParamText() ?? "$0"
      guard statementReturnsIdentifier(onlyStmt, named: paramName) else { return }

      violations.append(
        SyntaxViolation(
          position: memberAccess.declName.baseName.positionAfterSkippingLeadingTrivia,
          reason: "Prefer Array(seq) over seq.map { $0 }",
          severity: configuration.severity,
          confidence: .medium,
        ),
      )
    }

    private func statementReturnsIdentifier(
      _ stmt: CodeBlockItemSyntax, named name: String
    ) -> Bool {
      let identifier =
        stmt.item.as(DeclReferenceExprSyntax.self)
        ?? stmt.item.as(ReturnStmtSyntax.self)?.expression?.as(DeclReferenceExprSyntax.self)
      return identifier?.baseName.text == name
    }
  }
}

private extension ClosureSignatureSyntax {
  func singleInputParamText() -> String? {
    if let list = parameterClause?.as(ClosureShorthandParameterListSyntax.self), list.count == 1 {
      return list.first?.name.text
    }
    if let clause = parameterClause?.as(ClosureParameterClauseSyntax.self),
      clause.parameters.count == 1,
      clause.parameters.first?.secondName == nil
    {
      return clause.parameters.first?.firstName.text
    }
    return nil
  }
}
