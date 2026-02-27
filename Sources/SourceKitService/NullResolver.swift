/// No-op resolver used when `--sourcekit` is not passed.
///
/// Returns nil/empty for all queries. Checks fall back to syntax-only analysis.
public struct NullResolver: TypeResolver {
    public var isAvailable: Bool { false }

    public init() {}

    public func resolveType(inFile _: String, offset _: Int) async -> ResolvedType? {
        nil
    }

    public func indexFile(_: String) async -> FileIndex? {
        nil
    }

    public func expressionTypes(inFile _: String) async -> [ExpressionTypeInfo] {
        []
    }
}
