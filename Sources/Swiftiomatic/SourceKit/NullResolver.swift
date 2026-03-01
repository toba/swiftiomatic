/// No-op ``TypeResolver`` used when `--sourcekit` is not passed
///
/// Returns `nil` or empty for all queries so that rules fall back to
/// syntax-only analysis without requiring a SourceKit connection.
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
