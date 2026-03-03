import SwiftSyntax

/// Detects SwiftUI layout anti-patterns such as nested navigation stacks and
/// conflicting scrollable containers
///
/// Used by both `SwiftUILayoutCheck` (suggest) and `SwiftUILayoutRule` (lint).
enum SwiftUILayoutDetector {
    /// Container view names tracked for nesting analysis
    static let trackedContainers: Set<String> = [
        "NavigationStack", "List", "ScrollView", "GeometryReader",
        "VStack", "HStack", "ZStack", "Form",
    ]

    /// Containers that provide their own scrolling behavior
    static let unboundedContainers: Set<String> = ["List", "ScrollView", "Form"]

    /// Stack containers that can hold multiple children
    static let stackContainers: Set<String> = ["VStack", "HStack", "ZStack"]

    /// A detected layout anti-pattern with a reason and suggested fix
    struct LayoutIssue {
        let reason: String
        let suggestion: String
        let isHighSeverity: Bool
    }

    /// Checks for `NavigationStack` nested inside another `NavigationStack`
    ///
    /// - Parameters:
    ///   - callee: The name of the container being entered.
    ///   - containerStack: The current nesting stack of container names.
    /// - Returns: A ``LayoutIssue`` if double nesting is detected.
    static func checkNestedNavigationStack(
        callee: String,
        containerStack: [String],
    ) -> LayoutIssue? {
        guard callee == "NavigationStack", containerStack.contains("NavigationStack") else {
            return nil
        }
        return LayoutIssue(
            reason: "Nested NavigationStack — causes double navigation bars and broken navigation",
            suggestion: "Remove the inner NavigationStack; only the root view should own one",
            isHighSeverity: true,
        )
    }

    /// Checks for `List` inside `ScrollView` since `List` already scrolls
    ///
    /// - Parameters:
    ///   - callee: The name of the container being entered.
    ///   - containerStack: The current nesting stack of container names.
    /// - Returns: A ``LayoutIssue`` if the conflict is detected.
    static func checkListInsideScrollView(
        callee: String,
        containerStack: [String],
    ) -> LayoutIssue? {
        guard callee == "List", containerStack.contains("ScrollView") else { return nil }
        return LayoutIssue(
            reason: "List inside ScrollView — List has built-in scrolling, nesting causes conflicts",
            suggestion: "Remove the outer ScrollView or replace List with ForEach",
            isHighSeverity: true,
        )
    }

    /// Checks for `GeometryReader` inside `ScrollView` where the proposed size is undefined
    ///
    /// - Parameters:
    ///   - callee: The name of the container being entered.
    ///   - containerStack: The current nesting stack of container names.
    /// - Returns: A ``LayoutIssue`` if the conflict is detected.
    static func checkGeometryReaderInsideScrollView(
        callee: String,
        containerStack: [String],
    ) -> LayoutIssue? {
        guard callee == "GeometryReader", containerStack.contains("ScrollView") else { return nil }
        return LayoutIssue(
            reason: "GeometryReader inside ScrollView — proposed size is undefined in the scroll axis",
            suggestion: "Move GeometryReader outside the ScrollView or use a fixed frame",
            isHighSeverity: true,
        )
    }

    /// Checks for multiple unbounded containers competing for space inside a stack
    ///
    /// - Parameters:
    ///   - containerStack: The current nesting stack of container names.
    /// - Returns: A ``LayoutIssue`` if two or more unbounded containers share a stack parent.
    static func checkMultipleUnboundedContainers(
        containerStack: [String],
    ) -> LayoutIssue? {
        guard let current = containerStack.last, unboundedContainers.contains(current) else {
            return nil
        }
        guard
            let stackIndex = containerStack.dropLast().lastIndex(where: {
                stackContainers.contains($0)
            })
        else { return nil }

        let childrenAfterStack = containerStack[(stackIndex + 1)...]
        let hasInterveningStack = childrenAfterStack.dropLast().contains {
            stackContainers.contains($0)
        }
        guard !hasInterveningStack else { return nil }

        let unboundedCount = childrenAfterStack.count(where: { unboundedContainers.contains($0) })
        guard unboundedCount >= 2 else { return nil }

        let stackName = containerStack[stackIndex]
        return LayoutIssue(
            reason:
            "Multiple unbounded containers (\(unboundedCount)) inside \(stackName) — they compete for space",
            suggestion: "Give explicit frames to each container or restructure the layout",
            isHighSeverity: false,
        )
    }
}
