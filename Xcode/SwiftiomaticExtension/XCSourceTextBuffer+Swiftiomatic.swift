import XcodeKit

extension XCSourceTextBuffer {
    /// UTIs the extension can handle.
    static let supportedContentUTIs: Set<String> = [
        "public.swift-source",
        "com.apple.dt.playground",
        "com.apple.dt.playgroundpage",
    ]

    /// Whether the buffer's content type is a Swift source file.
    var isSwiftSource: Bool {
        Self.supportedContentUTIs.contains(contentUTI)
    }

    /// Infers the indentation string from the buffer's tab/space settings.
    var detectedIndentation: String {
        if usesTabsForIndentation {
            return "\t"
        }
        return String(repeating: " ", count: indentationWidth)
    }
}
