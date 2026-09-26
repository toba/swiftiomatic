/// One role-tagged location that supports a lint finding, in the form the reporters record.
public struct LintEvidence: Sendable {
    public let role: EvidenceRole
    public let file: String?
    public let line: Int?
    public let column: Int?
    public let message: String

    public init(role: EvidenceRole, file: String?, line: Int?, column: Int?, message: String) {
        self.role = role
        self.file = file
        self.line = line
        self.column = column
        self.message = message
    }
}
