import SwiftSyntax

/// Shared SwiftUI container nesting detection used by both
/// `SwiftUILayoutCheck` (suggest) and `SwiftUILayoutRule` (lint).
enum SwiftUIContainerHelpers {
    /// Container names tracked for nesting analysis.
    static let trackedContainers: Set<String> = [
        "NavigationStack", "List", "ScrollView", "GeometryReader",
        "VStack", "HStack", "ZStack", "Form",
    ]

    /// Containers that provide their own scrolling.
    static let unboundedContainers: Set<String> = ["List", "ScrollView", "Form"]

    /// Stack containers that can hold multiple children.
    static let stackContainers: Set<String> = ["VStack", "HStack", "ZStack"]

    /// A detected layout issue.
    struct LayoutIssue {
        let reason: String
        let suggestion: String
        let isHighSeverity: Bool
    }

    /// Check for NavigationStack nested inside another NavigationStack.
    static func checkNestedNavigationStack(
        callee: String,
        containerStack: [String]
    ) -> LayoutIssue? {
        guard callee == "NavigationStack", containerStack.contains("NavigationStack") else {
            return nil
        }
        return LayoutIssue(
            reason: "Nested NavigationStack — causes double navigation bars and broken navigation",
            suggestion: "Remove the inner NavigationStack; only the root view should own one",
            isHighSeverity: true
        )
    }

    /// Check for List inside ScrollView (List already scrolls).
    static func checkListInsideScrollView(
        callee: String,
        containerStack: [String]
    ) -> LayoutIssue? {
        guard callee == "List", containerStack.contains("ScrollView") else { return nil }
        return LayoutIssue(
            reason: "List inside ScrollView — List has built-in scrolling, nesting causes conflicts",
            suggestion: "Remove the outer ScrollView or replace List with ForEach",
            isHighSeverity: true
        )
    }

    /// Check for GeometryReader inside ScrollView (undefined proposed size).
    static func checkGeometryReaderInsideScrollView(
        callee: String,
        containerStack: [String]
    ) -> LayoutIssue? {
        guard callee == "GeometryReader", containerStack.contains("ScrollView") else { return nil }
        return LayoutIssue(
            reason: "GeometryReader inside ScrollView — proposed size is undefined in the scroll axis",
            suggestion: "Move GeometryReader outside the ScrollView or use a fixed frame",
            isHighSeverity: true
        )
    }

    /// Check for multiple unbounded containers competing for space inside a stack.
    static func checkMultipleUnboundedContainers(
        containerStack: [String]
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

        let unboundedCount = childrenAfterStack.filter { unboundedContainers.contains($0) }.count
        guard unboundedCount >= 2 else { return nil }

        let stackName = containerStack[stackIndex]
        return LayoutIssue(
            reason: "Multiple unbounded containers (\(unboundedCount)) inside \(stackName) — they compete for space",
            suggestion: "Give explicit frames to each container or restructure the layout",
            isHighSeverity: false
        )
    }
}
