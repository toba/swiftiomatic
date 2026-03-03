/// No-op ``TypeResolver`` used when `--sourcekit` is not passed
///
/// Returns `nil` or empty for all queries so that rules fall back to
/// syntax-only analysis without requiring a SourceKit connection.
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
