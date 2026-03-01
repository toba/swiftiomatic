/// A collection of keys and values as parsed out of SourceKit, with many conveniences for accessing analysis-specific
/// values.
struct SourceKitDictionary {
    /// The underlying SourceKit dictionary.
    let value: [String: SourceKitValue]
    /// The cached substructure for this dictionary. Empty if there is no substructure.
    let substructure: [Self]

    /// The kind of Swift expression represented by this dictionary, if it is an expression.
    let expressionKind: ExpressionKind?
    /// The kind of Swift declaration represented by this dictionary, if it is a declaration.
    let declarationKind: SwiftDeclarationKind?
    /// The kind of Swift statement represented by this dictionary, if it is a statement.
    let statementKind: StatementKind?

    /// The accessibility level for this dictionary, if it is a declaration.
    let accessibility: AccessControlLevel?

    /// Creates a SourceKit dictionary given a `[String: SourceKitValue]` input.
    ///
    /// - parameter value: The input dictionary.
    init(_ value: [String: SourceKitValue]) {
        self.value = value

        let substructure = value["key.substructure"]?.arrayValue ?? []
        self.substructure = substructure.compactMap(\.dictionaryValue).map(Self.init)

        let stringKind = value["key.kind"]?.stringValue
        expressionKind = stringKind.flatMap(ExpressionKind.init)
        declarationKind = stringKind.flatMap(SwiftDeclarationKind.init)
        statementKind = stringKind.flatMap(StatementKind.init)

        accessibility = value["key.accessibility"]?.stringValue.flatMap(
            AccessControlLevel.init(identifier:),
        )
    }

    /// Body length
    var bodyLength: ByteCount? {
        value["key.bodylength"]?.int64Value.map(ByteCount.init)
    }

    /// Body offset.
    var bodyOffset: ByteCount? {
        value["key.bodyoffset"]?.int64Value.map(ByteCount.init)
    }

    /// Kind.
    var kind: String? {
        value["key.kind"]?.stringValue
    }

    /// Length.
    var length: ByteCount? {
        value["key.length"]?.int64Value.map(ByteCount.init)
    }

    /// Name.
    var name: String? {
        value["key.name"]?.stringValue
    }

    /// Name length.
    var nameLength: ByteCount? {
        value["key.namelength"]?.int64Value.map(ByteCount.init)
    }

    /// Name offset.
    var nameOffset: ByteCount? {
        value["key.nameoffset"]?.int64Value.map(ByteCount.init)
    }

    /// Offset.
    var offset: ByteCount? {
        value["key.offset"]?.int64Value.map(ByteCount.init)
    }

    /// Returns byte range starting from `offset` with `length` bytes
    var byteRange: ByteRange? {
        guard let offset, let length else { return nil }
        return ByteRange(location: offset, length: length)
    }

    /// Setter accessibility.
    var setterAccessibility: String? {
        value["key.setter_accessibility"]?.stringValue
    }

    /// Type name.
    var typeName: String? {
        value["key.typename"]?.stringValue
    }

    /// The attribute for this dictionary, as returned by SourceKit.
    var attribute: String? {
        value["key.attribute"]?.stringValue
    }

    /// Module name in `@import` expressions.
    var moduleName: String? {
        value["key.modulename"]?.stringValue
    }

    /// The line number for this declaration.
    var line: Int64? {
        value["key.line"]?.int64Value
    }

    /// The column number for this declaration.
    var column: Int64? {
        value["key.column"]?.int64Value
    }

    /// The `SwiftDeclarationAttributeKind` values associated with this dictionary.
    var enclosedSwiftAttributes: [SwiftDeclarationAttributeKind] {
        swiftAttributes.compactMap(\.attribute)
            .compactMap(SwiftDeclarationAttributeKind.init(rawValue:))
    }

    /// The fully preserved SourceKit dictionaries for all the attributes associated with this dictionary.
    var swiftAttributes: [Self] {
        let array = value["key.attributes"]?.arrayValue ?? []
        return array.compactMap(\.dictionaryValue).map(Self.init)
    }

    var elements: [Self] {
        let elements = value["key.elements"]?.arrayValue ?? []
        return elements.compactMap(\.dictionaryValue).map(Self.init)
    }

    var entities: [Self] {
        let entities = value["key.entities"]?.arrayValue ?? []
        return entities.compactMap(\.dictionaryValue).map(Self.init)
    }

    var enclosedVarParameters: [Self] {
        substructure.flatMap { subDict -> [Self] in
            if subDict.declarationKind == .varParameter {
                return [subDict]
            }
            if subDict.expressionKind == .argument || subDict.expressionKind == .closure {
                return subDict.enclosedVarParameters
            }

            return []
        }
    }

    var enclosedArguments: [Self] {
        substructure.flatMap { subDict -> [Self] in
            guard subDict.expressionKind == .argument else {
                return []
            }

            return [subDict]
        }
    }

    var inheritedTypes: [String] {
        let array = value["key.inheritedtypes"]?.arrayValue ?? []
        return array.compactMap { $0.dictionaryValue?["key.name"]?.stringValue }
    }

    var secondarySymbols: [Self] {
        let array = value["key.secondary_symbols"]?.arrayValue ?? []
        return array.compactMap(\.dictionaryValue).map(Self.init)
    }
}

extension SourceKitDictionary {
    /// Block executed for every encountered entity during traversal of a dictionary.
    typealias TraverseBlock<T> = (
        _ parent: SourceKitDictionary,
        _ entity: SourceKitDictionary,
    )
        -> T?

    /// Traversing all substructures of the dictionary hierarchically, calling `traverseBlock` on each node.
    /// Traversing using depth first strategy, so deepest substructures will be passed to `traverseBlock` first.
    ///
    /// - parameter traverseBlock: block that will be called for each substructure in the dictionary.
    ///
    /// - returns: The list of substructure dictionaries with updated values from the traverse block.
    func traverseDepthFirst<T>(traverseBlock: (SourceKitDictionary) -> [T]?) -> [T] {
        var result: [T] = []
        traverseDepthFirst(collectingValuesInto: &result, traverseBlock: traverseBlock)
        return result
    }

    private func traverseDepthFirst<T>(
        collectingValuesInto array: inout [T],
        traverseBlock: (SourceKitDictionary) -> [T]?,
    ) {
        for subDict in substructure {
            subDict.traverseDepthFirst(collectingValuesInto: &array, traverseBlock: traverseBlock)

            if let collectedValues = traverseBlock(subDict) {
                array += collectedValues
            }
        }
    }

    /// Traversing all entities of the dictionary hierarchically, calling `traverseBlock` on each node.
    /// Traversing using depth first strategy, so deepest substructures will be passed to `traverseBlock` first.
    ///
    /// - parameter traverseBlock: Block that will be called for each entity and its parent in the dictionary.
    ///
    /// - returns: The list of entity dictionaries with updated values from the traverse block.
    func traverseEntitiesDepthFirst<T>(traverseBlock: TraverseBlock<T>) -> [T] {
        var result: [T] = []
        traverseEntitiesDepthFirst(collectingValuesInto: &result, traverseBlock: traverseBlock)
        return result
    }

    private func traverseEntitiesDepthFirst<T>(
        collectingValuesInto array: inout [T], traverseBlock: TraverseBlock<T>,
    ) {
        for subDict in entities {
            subDict.traverseEntitiesDepthFirst(
                collectingValuesInto: &array,
                traverseBlock: traverseBlock,
            )

            if let collectedValue = traverseBlock(self, subDict) {
                array.append(collectedValue)
            }
        }
    }
}
