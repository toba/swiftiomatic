/// No-op ``TypeResolver`` used when `--sourcekit` is not passed
///
/// Returns `nil` or empty for all queries so that rules fall back to
/// syntax-only analysis without requiring a SourceKit connection.
struct NullResolver: TypeResolver {
    public var isAvailable: Bool {
        false
    }

    init() {}

    public func resolveType(inFile _: String, offset _: Int) -> ResolvedType? {
        nil
    }

    public func indexFile(_: String) -> FileIndex? {
        nil
    }

    public func expressionTypes(inFile _: String) -> [ExpressionTypeInfo] {
        []
    }
}
