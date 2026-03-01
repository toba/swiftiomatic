/// Public metadata about a registered rule, suitable for display in the host app and external consumers.
public struct RuleCatalogEntry: Sendable, Identifiable, Codable, Hashable {
    public var id: String { identifier }
    public let identifier: String
    public let name: String
    public let description: String
    public let rationale: String?
    public let scope: Scope
    public let isCorrectable: Bool
    public let isOptIn: Bool

    package init(
        identifier: String,
        name: String,
        description: String,
        rationale: String?,
        scope: Scope,
        isCorrectable: Bool,
        isOptIn: Bool,
    ) {
        self.identifier = identifier
        self.name = name
        self.description = description
        self.rationale = rationale
        self.scope = scope
        self.isCorrectable = isCorrectable
        self.isOptIn = isOptIn
    }
}
