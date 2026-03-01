/// No-op resolver used when `--sourcekit` is not passed.
///
/// Returns nil/empty for all queries. Checks fall back to syntax-only analysis.
struct NullResolver: TypeResolver {
    package var isAvailable: Bool {
        false
    }

    init() {}

    package func resolveType(inFile _: String, offset _: Int) -> ResolvedType? {
        nil
    }

    package func indexFile(_: String) -> FileIndex? {
        nil
    }

    package func expressionTypes(inFile _: String) -> [ExpressionTypeInfo] {
        []
    }
}
