import SwiftSyntax

/// Compact-pipeline merge of all `SwitchCaseListSyntax` rewrites. Each
/// former rule's logic is gated on `context.shouldFormat(<RuleType>.self,
/// node:)`.
///
/// No node-local rules currently target `SwitchCaseListSyntax` via the
/// compact `transform` form. The unported entries below are tracked in 4f.
func rewriteSwitchCaseList(
    _ node: SwitchCaseListSyntax,
    parent: Syntax?,
    context: Context
) -> SwitchCaseListSyntax {
    var result = node
    // NoFallThroughOnlyCases — collapses `case`s whose only statement is
    // `fallthrough` into the following case's pattern list. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Redundancies/NoFallThroughOnlyCases.swift`.
    if context.shouldFormat(NoFallThroughOnlyCases.self, node: Syntax(result)) {
        result = applyNoFallThroughOnlyCases(result, context: context)
    }

    return result
}

/// Pre-traversal scan used by `NoFallThroughOnlyCases.willEnter` to emit
/// findings against the original (still-attached) node so source locations
/// are accurate.
func noFallThroughOnlyCasesDiagnoseInPlace(
    _ node: SwitchCaseListSyntax,
    context: Context
) {
    _ = applyNoFallThroughOnlyCasesImpl(node, context: context, diagnose: true)
}

private func applyNoFallThroughOnlyCases(
    _ node: SwitchCaseListSyntax,
    context: Context
) -> SwitchCaseListSyntax {
    applyNoFallThroughOnlyCasesImpl(node, context: context, diagnose: false)
}

private func applyNoFallThroughOnlyCasesImpl(
    _ node: SwitchCaseListSyntax,
    context: Context,
    diagnose: Bool
) -> SwitchCaseListSyntax {
    var newChildren: [SwitchCaseListSyntax.Element] = []
    var fallThroughOnlyCases: [SwitchCaseSyntax] = []

    func flushViolations() {
        for node in fallThroughOnlyCases { newChildren.append(.switchCase(node)) }
        fallThroughOnlyCases.removeAll()
    }

    for element in node {
        guard let switchCase = element.as(SwitchCaseSyntax.self) else {
            // `#if` block or similar — partitions the merge sets.
            flushViolations()
            newChildren.append(element)
            continue
        }

        if isMergeableFallThroughOnly(switchCase) {
            fallThroughOnlyCases.append(switchCase)
        } else {
            guard !fallThroughOnlyCases.isEmpty else {
                newChildren.append(.switchCase(switchCase))
                continue
            }

            if canMergeWithPreviousCases(switchCase) {
                newChildren.append(
                    .switchCase(
                        mergedCases(
                            fallThroughOnlyCases + [switchCase],
                            context: context,
                            diagnose: diagnose
                        )
                    )
                )
            } else {
                newChildren.append(
                    .switchCase(
                        mergedCases(
                            fallThroughOnlyCases, context: context, diagnose: diagnose
                        )
                    )
                )
                newChildren.append(.switchCase(switchCase))
            }

            fallThroughOnlyCases.removeAll()
        }
    }

    flushViolations()
    return SwitchCaseListSyntax(newChildren)
}

private func canMergeWithPreviousCases(_ node: SwitchCaseSyntax) -> Bool {
    node.label.is(SwitchCaseLabelSyntax.self) && !containsValueBindingPattern(node.label)
}

private func containsValueBindingPattern(_ node: SwitchCaseSyntax.Label) -> Bool {
    switch node {
        case let .case(label): containsValueBindingPattern(Syntax(label))
        case .default: false
    }
}

private func containsValueBindingPattern(_ node: Syntax) -> Bool {
    if node.is(ValueBindingPatternSyntax.self) { return true }
    for child in node.children(viewMode: .sourceAccurate) {
        if containsValueBindingPattern(child) { return true }
    }
    return false
}

private func isMergeableFallThroughOnly(_ switchCase: SwitchCaseSyntax) -> Bool {
    guard switchCase.label.is(SwitchCaseLabelSyntax.self) else { return false }

    guard let onlyStatement = switchCase.statements.firstAndOnly,
          onlyStatement.item.is(FallThroughStmtSyntax.self)
    else {
        return false
    }

    if containsValueBindingPattern(switchCase.label) { return false }

    if switchCase.allPrecedingTrivia
        .drop(while: { !$0.isNewline }).contains(where: { $0.isComment })
    {
        return false
    }
    if onlyStatement.allPrecedingTrivia
        .drop(while: { !$0.isNewline }).contains(where: { $0.isComment })
    {
        return false
    }
    if onlyStatement.allFollowingTrivia
        .prefix(while: { !$0.isNewline }).contains(where: { $0.isComment })
    {
        return false
    }
    return true
}

private func mergedCases(
    _ cases: [SwitchCaseSyntax],
    context: Context,
    diagnose: Bool = false
) -> SwitchCaseSyntax {
    precondition(!cases.isEmpty, "Must have at least one case to merge")
    if cases.count == 1 { return cases.first! }

    var newCaseItems: [SwitchCaseItemSyntax] = []
    let labels = cases.lazy.compactMap { $0.label.as(SwitchCaseLabelSyntax.self) }

    for label in labels.dropLast() {
        if diagnose {
            NoFallThroughOnlyCases.diagnose(.collapseCase, on: label, context: context)
        }

        newCaseItems.append(contentsOf: label.caseItems.dropLast())

        var lastItem = label.caseItems.last!
        lastItem.trailingComma = TokenSyntax.commaToken(trailingTrivia: [.spaces(1)])
        newCaseItems.append(lastItem)
    }
    newCaseItems.append(contentsOf: labels.last!.caseItems)

    var lastLabel = labels.last!
    lastLabel.caseItems = SwitchCaseItemListSyntax(newCaseItems)

    var lastCase = cases.last!
    lastCase.label = .case(lastLabel)

    lastCase.leadingTrivia =
        cases.first!.leadingTrivia.withoutLastLine() + lastCase.leadingTrivia
    return lastCase
}

extension Finding.Message {
    fileprivate static var collapseCase: Finding.Message {
        "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"
    }
}
