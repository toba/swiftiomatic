struct CaptureVariableRule: AnalyzerRule, CollectingRule {
  struct Variable: Hashable {
    let usr: String
    let offset: ByteCount
  }

  typealias USR = String
  typealias FileInfo = Set<USR>

  static let configuration = CaptureVariableConfiguration()

  var options = SeverityConfiguration<Self>(.warning)

  func collectInfo(for file: SwiftSource, compilerArguments: [String]) -> Self.FileInfo {
    file.declaredVariables(compilerArguments: compilerArguments)
  }

  func validate(
    file: SwiftSource,
    collectedInfo: [SwiftSource: Self.FileInfo],
    compilerArguments: [String],
  ) -> [RuleViolation] {
    file.captureListVariables(compilerArguments: compilerArguments)
      .filter { capturedVariable in
        collectedInfo.values.contains { $0.contains(capturedVariable.usr) }
      }
      .map {
        RuleViolation(
          configuration: Self.configuration,
          severity: options.severity,
          location: Location(file: file, byteOffset: $0.offset),
        )
      }
  }
}

extension SwiftSource {
  fileprivate static var checkedDeclarationKinds: [SwiftDeclarationKind] {
    [.varClass, .varGlobal, .varInstance, .varStatic]
  }

  fileprivate func captureListVariableOffsets() -> Set<ByteCount> {
    Self.captureListVariableOffsets(parentEntity: structureDictionary)
  }

  fileprivate static func captureListVariableOffsets(parentEntity: SourceKitDictionary) -> Set<
    ByteCount,
  > {
    parentEntity.substructure
      .reversed()
      .reduce(into: (foundOffsets: Set<ByteCount>(), afterClosure: nil as ByteCount?)) {
        acc, entity in
        guard let offset = entity.offset else { return }

        if entity.expressionKind == .closure {
          acc.afterClosure = offset
        } else if let closureOffset = acc.afterClosure,
          closureOffset < offset,
          let length = entity.length,
          let nameLength = entity.nameLength,
          entity.declarationKind == .varLocal
        {
          acc.foundOffsets.insert(offset + length - nameLength)
        } else {
          acc.afterClosure = nil
        }

        acc.foundOffsets.formUnion(captureListVariableOffsets(parentEntity: entity))
      }
      .foundOffsets
  }

  fileprivate func captureListVariables(compilerArguments: [String]) -> Set<
    CaptureVariableRule.Variable,
  > {
    let offsets = captureListVariableOffsets()
    guard !offsets.isEmpty,
      let indexEntities = index(compilerArguments: compilerArguments)
    else {
      return Set()
    }

    return Set(
      indexEntities.traverseEntitiesDepthFirst { _, entity in
        guard
          let kind = entity.kind,
          kind.hasPrefix("source.lang.swift.ref.var."),
          let usr = entity.usr,
          let line = entity.line,
          let column = entity.column,
          let offset = stringView.byteOffset(forLine: line, bytePosition: column)
        else { return nil }
        return offsets.contains(offset)
          ? CaptureVariableRule.Variable(usr: usr, offset: offset) : nil
      },
    )
  }

  fileprivate func declaredVariableOffsets() -> Set<ByteCount> {
    Self.declaredVariableOffsets(parentStructure: structureDictionary)
  }

  fileprivate static func declaredVariableOffsets(parentStructure: SourceKitDictionary) -> Set<
    ByteCount,
  > {
    Set(
      parentStructure.traverseDepthFirst {
        let hasSetter = $0.setterAccessibility != nil
        let isAutoUnwrap = $0.typeName?.hasSuffix("!") ?? false
        guard
          hasSetter,
          !isAutoUnwrap,
          let declarationKind = $0.declarationKind,
          checkedDeclarationKinds.contains(declarationKind),
          !$0.enclosedSwiftAttributes.contains(.lazy),
          let nameOffset = $0.nameOffset
        else { return [] }
        return [nameOffset]
      },
    )
  }

  fileprivate func declaredVariables(compilerArguments: [String]) -> Set<CaptureVariableRule.USR> {
    let offsets = declaredVariableOffsets()
    guard !offsets.isEmpty,
      let indexEntities = index(compilerArguments: compilerArguments)
    else {
      return Set()
    }

    return Set(
      indexEntities.traverseEntitiesDepthFirst { _, entity in
        guard
          let declarationKind = entity.declarationKind,
          Self.checkedDeclarationKinds.contains(declarationKind),
          let line = entity.line,
          let column = entity.column,
          let offset = stringView.byteOffset(forLine: line, bytePosition: column),
          offsets.contains(offset)
        else { return nil }
        return entity.usr
      },
    )
  }

  fileprivate func index(compilerArguments: [String]) -> SourceKitDictionary? {
    guard
      let path,
      let response = try? Request.index(file: path, arguments: compilerArguments)
        .sendIfNotDisabled()
    else {
      SwiftiomaticError.indexingError(path: path, ruleID: CaptureVariableRule.identifier).print()
      return nil
    }

    return SourceKitDictionary(response)
  }
}

extension SourceKitDictionary {
  fileprivate var usr: String? {
    value["key.usr"]?.stringValue
  }
}
