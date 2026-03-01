import Foundation

/// Captures code and context information for an example of a triggering or
/// non-triggering style
public struct Example: Sendable {
    /// The contents of the example
    private(set) var code: String
    /// The untyped configuration to apply to the rule, if deviating from the default configuration.
    /// The structure should match what is expected as a configuration value for the rule being tested.
    ///
    /// For example, if the following YAML would be used to configure the rule:
    ///
    /// ```
    /// severity: warning
    /// ```
    ///
    /// Then the equivalent configuration value would be `["severity": "warning"]`.
    private(set) var configuration: [String: any Sendable]?
    /// Whether the example should be tested by prepending multibyte grapheme clusters
    ///
    /// - SeeAlso: addEmoji(_:)
    private(set) var shouldTestMultiByteOffsets: Bool
    /// Whether tests shall verify that the example wrapped in a comment doesn't trigger
    public private(set) var shouldTestWrappingInComment: Bool
    /// Whether tests shall verify that the example wrapped into a string doesn't trigger
    public private(set) var shouldTestWrappingInString: Bool
    /// Whether tests shall verify that the disabled rule (comment in the example) doesn't trigger
    public private(set) var shouldTestDisableCommand: Bool
    /// The path to the file where the example was created
    private(set) var file: StaticString
    /// The line in the file where the example was created
    var line: UInt
    /// Specifies whether the example should be excluded from the rule documentation.
    ///
    /// It can be set to `true` if an example has mainly been added as another test case, but is not suitable
    /// as a user example. User examples should be easy to understand. They should clearly show where and
    /// why a rule is applied and where not. Complex examples with rarely used language constructs or
    /// pathological use cases which are indeed important to test but not helpful for understanding can be
    /// hidden from the documentation with this option.
    public let isExcludedFromDocumentation: Bool

    /// Specifies whether the test example should be the only example run during the current test case execution.
    public var isFocused: Bool
}

extension Example {
    /// Create a new Example with the specified code, file, and line.
    /// - Parameters:
    ///   - code:                          The contents of the example.
    ///   - configuration:                 The untyped configuration to apply to the rule, if deviating from the default
    ///                                    configuration.
    ///   - shouldTestMultiByteOffsets:     Whether the example should be tested by prepending multibyte grapheme clusters.
    ///   - shouldTestWrappingInComment:    Whether test shall verify that the example wrapped in a comment doesn't
    ///                                    trigger.
    ///   - shouldTestWrappingInString:     Whether tests shall verify that the example wrapped into a string doesn't
    ///                                    trigger.
    ///   - shouldTestDisableCommand:       Whether tests shall verify that the disabled rule (comment in the example)
    ///                                    doesn't trigger.
    ///   - file:                          The path to the file where the example is located.
    ///                                    Defaults to the file where this initializer is called.
    ///   - line:                          The line in the file where the example is located.
    ///                                    Defaults to the line where this initializer is called.
    init(
        _ code: String,
        configuration: [String: any Sendable]? = nil,
        shouldTestMultiByteOffsets: Bool = true,
        shouldTestWrappingInComment: Bool = true,
        shouldTestWrappingInString: Bool = true,
        shouldTestDisableCommand: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line,
        isExcludedFromDocumentation: Bool = false,
    ) {
        self.code = code
        self.configuration = configuration
        self.shouldTestMultiByteOffsets = shouldTestMultiByteOffsets
        self.file = file
        self.line = line
        self.isExcludedFromDocumentation = isExcludedFromDocumentation
        self.shouldTestWrappingInComment = shouldTestWrappingInComment
        self.shouldTestWrappingInString = shouldTestWrappingInString
        self.shouldTestDisableCommand = shouldTestDisableCommand
        isFocused = false
    }

    /// Returns the same example, but with the `code` that is passed in
    /// - Parameters:
    ///   - code: the new code to use in the modified example
    func with(code: String) -> Example {
        var new = self
        new.code = code
        return new
    }

    /// Returns a copy of the Example with all instances of the "↓" character removed.
    func removingViolationMarkers() -> Example {
        with(code: code.replacingOccurrences(of: "↓", with: ""))
    }
}

extension Example {
    /// Returns a copy with the given boolean property set to the specified value.
    private func setting(_ keyPath: WritableKeyPath<Self, Bool>, to value: Bool) -> Self {
        var new = self
        new[keyPath: keyPath] = value
        return new
    }

    func skipWrappingInCommentTest() -> Self {
        setting(\.shouldTestWrappingInComment, to: false)
    }

    func skipWrappingInStringTest() -> Self {
        setting(\.shouldTestWrappingInString, to: false)
    }

    func skipMultiByteOffsetTest() -> Self {
        setting(\.shouldTestMultiByteOffsets, to: false)
    }

    func skipDisableCommandTest() -> Self {
        setting(\.shouldTestDisableCommand, to: false)
    }

    /// Makes the current example focused. This is for debugging purposes only.
    func focused() -> Example { // sm:disable:this unused_declaration
        setting(\.isFocused, to: true)
    }
}

extension Example: Hashable {
    public static func == (lhs: Example, rhs: Example) -> Bool {
        // Ignoring file/line metadata because two Examples could represent
        // the same idea, but captured at two different points in the code
        lhs.code == rhs.code
            && lhs.configuration?.mapValues(String.init(describing:))
            == rhs.configuration?.mapValues(String.init(describing:))
    }

    public func hash(into hasher: inout Hasher) {
        // Ignoring file/line metadata because two Examples could represent
        // the same idea, but captured at two different points in the code
        hasher.combine(code)
        hasher.combine(configuration?.mapValues(String.init(describing:)))
    }
}

extension Example: Comparable {
    public static func < (lhs: Example, rhs: Example) -> Bool {
        lhs.code < rhs.code
    }
}

extension [Example] {
    /// Make these examples skip wrapping in comment tests.
    func skipWrappingInCommentTests() -> Self {
        map { $0.skipWrappingInCommentTest() }
    }

    /// Make these examples skip wrapping in string tests.
    func skipWrappingInStringTests() -> Self {
        map { $0.skipWrappingInStringTest() }
    }

    /// Make these examples skip multi-byte offset tests.
    func skipMultiByteOffsetTests() -> Self {
        map { $0.skipMultiByteOffsetTest() }
    }

    /// Make these examples skip disable command tests.
    func skipDisableCommandTests() -> Self {
        map { $0.skipDisableCommandTest() }
    }

    /// Remove all violation markers from the examples.
    func removingViolationMarker() -> Self {
        map { $0.removingViolationMarkers() }
    }
}
