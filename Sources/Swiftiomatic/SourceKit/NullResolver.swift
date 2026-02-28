/// No-op resolver used when `--sourcekit` is not passed.
///
/// Returns nil/empty for all queries. Checks fall back to syntax-only analysis.
struct NullResolver: TypeResolver {
    var isAvailable: Bool {
        false
    }

    init() {}

    func resolveType(inFile _: String, offset _: Int) -> ResolvedType? {
        nil
    }

    func indexFile(_: String) -> FileIndex? {
        nil
    }

    func expressionTypes(inFile _: String) -> [ExpressionTypeInfo] {
        []
    }
}
