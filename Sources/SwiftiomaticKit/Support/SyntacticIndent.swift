import SwiftSyntax

/// A lower bound on the column the pretty printer indents a node to
///
/// The printer indents a comment to the syntactic depth of the scope that holds it, whatever column
/// the trivia carries. A rule that budgets a comment wrap before the printer runs therefore reads a
/// stale column, and the wrapped line overflows once the printer adds its indentation. Flooring the
/// column with this value keeps the wrap stable in one pass.
///
/// The result is a floor, never an exact column, because a nested expression can add indentation
/// this walk does not model.
///
/// - Parameters:
///   - node: the node whose indent column is wanted, usually the token that owns the comment trivia
///   - context: the context that carries the configuration
/// - Returns: The column, counted from zero.
func syntacticIndentColumn(of node: Syntax?, context: Context) -> Int {
    // an indented case label sits one level below the switch, and its body one level below that
    let switchCaseSetting = context.configuration[IndentSwitchCases.self]
    let switchCaseLevels = switchCaseSetting.rewrite && switchCaseSetting.style == .indented ? 2 : 1

    var depth = 0
    var current = node

    while let scope = current {
        if scope.is(CodeBlockSyntax.self)
            || scope.is(MemberBlockSyntax.self)
            || scope.is(ClosureExprSyntax.self)
            || scope.is(AccessorBlockSyntax.self)
        {
            depth += 1
        } else if scope.is(SwitchCaseSyntax.self) { depth += switchCaseLevels }
        current = scope.parent
    }
    let width: Int

    switch context.configuration[IndentationSetting.self] {
        case let .spaces(count): width = count
        case let .tabs(count): width = count * context.configuration[TabWidth.self]
    }
    return depth * width
}
