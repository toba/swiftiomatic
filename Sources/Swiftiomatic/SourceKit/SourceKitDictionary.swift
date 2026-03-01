/// A parsed SourceKit response dictionary with typed accessors for common keys
///
/// Eagerly resolves the entity kind (expression, declaration, or statement)
/// and caches nested substructure so repeated traversals are allocation-free.
struct SourceKitDictionary {
    /// The raw key-value pairs from SourceKit
    let value: [String: SourceKitValue]
    /// Cached child substructure dictionaries (empty when none exist)
    let substructure: [Self]

    /// The expression kind, if this dictionary represents an expression
    let expressionKind: ExpressionKind?
    /// The declaration kind, if this dictionary represents a declaration
    let declarationKind: SwiftDeclarationKind?
    /// The statement kind, if this dictionary represents a statement
    let statementKind: StatementKind?

    /// The accessibility level, if this dictionary represents a declaration
    let accessibility: AccessControlLevel?

    /// Create a dictionary from raw SourceKit key-value pairs
    ///
    /// - Parameters:
    ///   - value: The raw `[String: SourceKitValue]` dictionary.
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

    /// The body length in bytes (`key.bodylength`)
    var bodyLength: ByteCount? {
        value["key.bodylength"]?.int64Value.map(ByteCount.init)
    }

    /// The body offset in bytes (`key.bodyoffset`)
    var bodyOffset: ByteCount? {
        value["key.bodyoffset"]?.int64Value.map(ByteCount.init)
    }

    /// The SourceKit kind UID string (`key.kind`)
    var kind: String? {
        value["key.kind"]?.stringValue
    }

    /// The total length in bytes (`key.length`)
    var length: ByteCount? {
        value["key.length"]?.int64Value.map(ByteCount.init)
    }

    /// The symbol name (`key.name`)
    var name: String? {
        value["key.name"]?.stringValue
    }

    /// The name length in bytes (`key.namelength`)
    var nameLength: ByteCount? {
        value["key.namelength"]?.int64Value.map(ByteCount.init)
    }

    /// The name offset in bytes (`key.nameoffset`)
    var nameOffset: ByteCount? {
        value["key.nameoffset"]?.int64Value.map(ByteCount.init)
    }

    /// The starting byte offset (`key.offset`)
    var offset: ByteCount? {
        value["key.offset"]?.int64Value.map(ByteCount.init)
    }

    /// The ``ByteRange`` spanning from ``offset`` for ``length`` bytes
    var byteRange: ByteRange? {
        guard let offset, let length else { return nil }
        return ByteRange(location: offset, length: length)
    }

    /// The setter accessibility level UID string (`key.setter_accessibility`)
    var setterAccessibility: String? {
        value["key.setter_accessibility"]?.stringValue
    }

    /// The type name string (`key.typename`)
    var typeName: String? {
        value["key.typename"]?.stringValue
    }

    /// The attribute UID string (`key.attribute`)
    var attribute: String? {
        value["key.attribute"]?.stringValue
    }

    /// The module name in `@import` expressions (`key.modulename`)
    var moduleName: String? {
        value["key.modulename"]?.stringValue
    }

    /// The one-based line number (`key.line`)
    var line: Int64? {
        value["key.line"]?.int64Value
    }

    /// The one-based column number (`key.column`)
    var column: Int64? {
        value["key.column"]?.int64Value
    }

    /// The ``SwiftDeclarationAttributeKind`` values associated with this dictionary
    var enclosedSwiftAttributes: [SwiftDeclarationAttributeKind] {
        swiftAttributes.compactMap(\.attribute)
            .compactMap(SwiftDeclarationAttributeKind.init(rawValue:))
    }

    /// The full SourceKit dictionaries for all attributes associated with this entity
    var swiftAttributes: [Self] {
        let array = value["key.attributes"]?.arrayValue ?? []
        return array.compactMap(\.dictionaryValue).map(Self.init)
    }

    /// The child element dictionaries (`key.elements`)
    var elements: [Self] {
        let elements = value["key.elements"]?.arrayValue ?? []
        return elements.compactMap(\.dictionaryValue).map(Self.init)
    }

    /// The child entity dictionaries (`key.entities`)
    var entities: [Self] {
        let entities = value["key.entities"]?.arrayValue ?? []
        return entities.compactMap(\.dictionaryValue).map(Self.init)
    }

    /// All `varParameter` declarations reachable through substructure, recursing into arguments and closures
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

    /// All argument expressions in the immediate substructure
    var enclosedArguments: [Self] {
        substructure.flatMap { subDict -> [Self] in
            guard subDict.expressionKind == .argument else {
                return []
            }

            return [subDict]
        }
    }

    /// The names of inherited types (`key.inheritedtypes`)
    var inheritedTypes: [String] {
        let array = value["key.inheritedtypes"]?.arrayValue ?? []
        return array.compactMap { $0.dictionaryValue?["key.name"]?.stringValue }
    }

    /// Secondary symbols associated with this entity (`key.secondary_symbols`)
    var secondarySymbols: [Self] {
        let array = value["key.secondary_symbols"]?.arrayValue ?? []
        return array.compactMap(\.dictionaryValue).map(Self.init)
    }
}

extension SourceKitDictionary {
    /// Block executed for every encountered entity during dictionary traversal
    typealias TraverseBlock<T> = (
        _ parent: SourceKitDictionary,
        _ entity: SourceKitDictionary,
    )
        -> T?

    /// Traverse all substructures depth-first, collecting values from each node
    ///
    /// Deepest substructures are visited first, so leaf nodes are processed
    /// before their parents.
    ///
    /// - Parameters:
    ///   - traverseBlock: A closure called for each substructure dictionary.
    ///     Return values to collect, or `nil` to skip.
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

    /// Traverse all entities depth-first, collecting values from each parent-entity pair
    ///
    /// - Parameters:
    ///   - traverseBlock: A closure called with the parent and child entity dictionaries.
    ///     Return a value to collect, or `nil` to skip.
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
