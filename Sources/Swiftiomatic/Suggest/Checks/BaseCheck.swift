import SwiftSyntax

/// Base class for single-file checks providing common infrastructure.
open class BaseCheck: SyntaxVisitor, Check, @unchecked Sendable {
    public let filePath: String
    public let typeResolver: (any TypeResolver)?
    public internal(set) var findings: [Finding] = []

    /// Pending type resolution queries collected during the synchronous walk.
    /// Subclasses append queries here; `resolveTypeQueries()` processes them after walk completes.
    public var pendingTypeQueries: [TypeQuery] = []

    public init(filePath: String, typeResolver: (any TypeResolver)? = nil) {
        self.filePath = filePath
        self.typeResolver = typeResolver
        super.init(viewMode: .sourceAccurate)
    }

    /// Called after `walk()` completes to process pending SourceKit queries.
    /// Override in subclasses that collect queries during the synchronous walk.
    open func resolveTypeQueries() async {
        // Default: no-op. Subclasses override when they have pending queries.
    }

    /// Add a finding at the given node's location.
    public func addFinding(
        at node: some SyntaxProtocol,
        category: Category,
        severity: Severity,
        message: String,
        suggestion: String? = nil,
        confidence: Confidence
    ) {
        let location = node.startLocation(converter: .init(
            fileName: filePath,
            tree: node.root
        ))
        findings.append(Finding(
            category: category,
            severity: severity,
            file: filePath,
            line: location.line,
            column: location.column,
            message: message,
            suggestion: suggestion,
            confidence: confidence
        ))
    }
}

/// A deferred SourceKit query to be resolved after the synchronous walk completes.
public struct TypeQuery: Sendable {
    /// Byte offset in the source file.
    public let offset: Int

    /// Arbitrary context the check needs to process the result.
    public let context: String

    /// Line number for finding location.
    public let line: Int

    /// Column number for finding location.
    public let column: Int

    public init(offset: Int, context: String, line: Int = 0, column: Int = 0) {
        self.offset = offset
        self.context = context
        self.line = line
        self.column = column
    }
}
