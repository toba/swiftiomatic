import Foundation

/// The indenting mode to use for #if/#endif statements
enum IndentMode: String, CaseIterable {
    case indent
    case noIndent = "no-indent"
    case preserve
    case outdent

    init?(rawValue: String) {
        switch rawValue {
            case "indent":
                self = .indent
            case "no-indent", "noindent":
                self = .noIndent
            case "preserve":
                self = .preserve
            case "outdent":
                self = .outdent
            default:
                return nil
        }
    }
}

/// Wrap mode for arguments
enum WrapMode: String, CaseIterable {
    case beforeFirst = "before-first"
    case afterFirst = "after-first"
    case preserve
    case disabled
    case `default`

    init?(rawValue: String) {
        switch rawValue {
            case "before-first", "beforefirst":
                self = .beforeFirst
            case "after-first", "afterfirst":
                self = .afterFirst
            case "preserve":
                self = .preserve
            case "disabled":
                self = .disabled
            case "default":
                self = .default
            default:
                return nil
        }
    }
}

/// Wrap enum cases
enum WrapEnumCases: String, CaseIterable {
    case always
    case withValues = "with-values"
}

/// Argument type for stripping
enum ArgumentStrippingMode: String, CaseIterable {
    case unnamedOnly = "unnamed-only"
    case closureOnly = "closure-only"
    case all = "always"
}

/// Wrap mode for @ attributes
enum AttributeMode: String, CaseIterable {
    case prevLine = "prev-line"
    case sameLine = "same-line"
    case preserve
}

/// Where to place the else or catch in an if/else or do/catch statement
enum ElsePosition: String, CaseIterable {
    case sameLine = "same-line"
    case nextLine = "next-line"
}

/// Where to place the else in a guard statement
enum GuardElsePosition: String, CaseIterable {
    case sameLine = "same-line"
    case nextLine = "next-line"
    case auto
}

/// Where to place the access control keyword of an extension
enum ExtensionACLPlacement: String, CaseIterable {
    case onExtension = "on-extension"
    case onDeclarations = "on-declarations"
}

/// Wrapping behavior for the return type of a function declaration
enum WrapReturnType: String, CaseIterable {
    case preserve
    /// `-> ReturnType` is wrapped to the line after the closing paren
    /// if the function signature spans multiple lines
    case ifMultiline = "if-multiline"
    /// `-> ReturnType` is never wrapped, and always include on the same line as the closing paren
    case never
}

/// Wrapping behavior for effects (`async`, `throws`)
enum WrapEffects: String, CaseIterable {
    case preserve
    /// `async` and `throws` are wrapped to the line after the closing paren
    /// if the function signature spans multiple lines
    case ifMultiline = "if-multiline"
    /// `async` and `throws` are never wrapped, and are always included on the same line as the closing paren
    case never
}

/// Argument type for whether explicit or inferred properties are preferred
enum PropertyTypes: String, CaseIterable {
    /// Preserves the type as a part of the property definition:
    /// `let foo: Foo = Foo()` becomes `let foo: Foo = .init()`
    case explicit

    /// Uses type inference to omit the type in the property definition:
    /// `let foo: Foo = Foo()` becomes `let foo = Foo()`
    case inferred

    /// Uses `.inferred` for properties within local scopes (method bodies, etc.),
    /// but `.explicit` for globals and properties within types.
    ///  - This is because type checking for globals and type properties
    ///    using inferred types can be more expensive.
    ///    https://twitter.com/uint_min/status/1441448033988722691?s=21
    case inferLocalsOnly = "infer-locals-only"
}

/// Argument type for empty brace spacing behavior
enum EmptyBracesSpacing: String, CaseIterable {
    case spaced
    case noSpace = "no-space"
    case linebreak
}

/// Wrapping behavior for multi-line ternary operators
enum TernaryOperatorWrapMode: String, CaseIterable {
    /// Wraps ternary operators using the default `wrap` behavior,
    /// which performs the minimum amount of wrapping necessary.
    case `default`
    /// Wraps long / multi-line ternary operators before each of the component operators
    case beforeOperators = "before-operators"
}

enum StringInterpolationWrapMode: String, CaseIterable {
    /// Wraps string interpolation if necessary based on the max line length
    case `default`
    /// Preserve existing wrapping for string interpolations,
    /// and don't insert line breaks.
    case preserve
}

/// Whether or not to remove `-> Void` from closures
enum ClosureVoidReturn: String, CaseIterable {
    case remove
    case preserve
}

enum TrailingCommas: String, CaseIterable {
    case never
    case always
    case collectionsOnly = "collections-only"
    case multiElementLists = "multi-element-lists"
}

/// Whether to insert, remove, or preserve spaces around operators
enum OperatorSpacingMode: String, CaseIterable {
    case insert = "spaced"
    case remove = "no-space"
    case preserve
}

/// Grouping for numeric literals
enum Grouping: Equatable, RawRepresentable, CustomStringConvertible {
    case ignore
    case none
    case group(Int, Int)

    init?(rawValue: String) {
        switch rawValue {
            case "ignore":
                self = .ignore
            case "none":
                self = .none
            default:
                let parts = rawValue.components(separatedBy: ",").map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                guard (1 ... 2).contains(parts.count),
                      let group = parts.first.flatMap(Int.init),
                      let threshold = parts.last.flatMap(Int.init)
                else {
                    return nil
                }
                self = (group == 0) ? .none : .group(group, threshold)
        }
    }

    var rawValue: String {
        switch self {
            case .ignore:
                return "ignore"
            case .none:
                return "none"
            case let .group(group, threshold):
                return "\(group),\(threshold)"
        }
    }

    var description: String {
        rawValue
    }
}

/// Grouping for sorting imports
enum ImportGrouping: String, CaseIterable {
    case alpha
    case length
    case testableFirst = "testable-first"
    case testableLast = "testable-last"
}

/// Self insertion mode
enum SelfMode: String, CaseIterable {
    case insert
    case remove
    case initOnly = "init-only"
}

/// Optionals mode
enum OptionalsMode: String, CaseIterable {
    case preserveStructInits = "preserve-struct-inits"
    case exceptPropertiesDeprecated = "except-properties"
    case always
}

/// Argument type for yoda conditions
enum YodaMode: String, CaseIterable {
    case literalsOnly = "literals-only"
    case always
}

/// Argument type for asset literals
enum AssetLiteralWidth: String, CaseIterable {
    case actualWidth = "actual-width"
    case visualWidth = "visual-width"
}

/// Whether or not to mark types / extensions
enum MarkMode: String, CaseIterable {
    case always
    case never
    case ifNotEmpty = "if-not-empty"
}

/// Whether to convert types to enum
enum EnumNamespacesMode: String, CaseIterable {
    case always
    case structsOnly = "structs-only"
}

/// Whether to add spacing around a delimiter
enum DelimiterSpacing: String, CaseIterable {
    case spaced
    case spaceAfter = "space-after"
    case noSpace = "no-space"
}

/// Declaration organization mode
enum DeclarationOrganizationMode: String, CaseIterable {
    /// Organize declarations by visibility
    case visibility
    /// Organize declarations by type
    case type
}

/// Treatment of MARK comments in type bodies
enum TypeBodyMarks: String, CaseIterable {
    /// Preserve all existing MARK comments in type bodies
    case preserve
    /// Remove MARK comments that don't match expected visibility/declaration kind marks
    case remove
}

/// Whether to insert or remove blank lines from the start / end of type bodies
enum TypeBlankLines: String, CaseIterable {
    case remove
    case insert
    case preserve
}

/// Treatment of semicolons
enum SemicolonsMode: String, CaseIterable {
    case inlineOnly = "inline-only"
    case never
}

/// When initializing an optional value type,
/// is it necessary to explicitly declare a default value
enum NilInitType: String, CaseIterable {
    /// Remove redundant `nil` if it is added as default value
    case remove

    /// Add `nil` as default if not explicitly declared
    case insert
}

/// Placement for closing paren in a function call or definition
enum ClosingParenPosition: String, CaseIterable {
    case balanced
    case sameLine = "same-line"
    case `default`
}

enum SwiftUIPropertiesSortMode: String, CaseIterable {
    /// No sorting
    case none
    /// Sort alphabetically
    case alphabetize
    /// Group all properties of the same type in order of the first time each property appears
    case firstAppearanceSort = "first-appearance-sort"
}

enum EquatableMacro: Equatable, RawRepresentable, CustomStringConvertible {
    /// No equatable macro
    case none
    /// The name and the module for the macro, e.g. `@Equatable,EquatableMacroLib`
    case macro(String, module: String)

    init?(rawValue: String) {
        let components = rawValue.components(separatedBy: ",")
        if components.count == 2 {
            self = .macro(components[0], module: components[1])
        } else if rawValue == "none" {
            self = .none
        } else {
            return nil
        }
    }

    var rawValue: String {
        switch self {
            case .none:
                return "none"
            case let .macro(name, module: module):
                return "\(name),\(module)"
        }
    }

    var description: String {
        rawValue
    }
}

enum BlankLineAfterSwitchCase: String, CaseIterable {
    /// Always add blank lines after switch cases
    case always
    /// Add blank lines after multiline switch cases only
    case multilineOnly = "multiline-only"
}

enum URLMacro: Equatable, RawRepresentable, CustomStringConvertible {
    /// No URL macro
    case none
    /// The name and the module for the macro, e.g. `#URL,URLFoundation`
    case macro(String, module: String)

    init?(rawValue: String) {
        let components = rawValue.components(separatedBy: ",")
        if components.count == 2 {
            self = .macro(components[0], module: components[1])
        } else if rawValue == "none" {
            self = .none
        } else {
            return nil
        }
    }

    var rawValue: String {
        switch self {
            case .none:
                return "none"
            case let .macro(name, module: module):
                return "\(name),\(module)"
        }
    }

    var description: String {
        rawValue
    }
}

/// Mode for preferring synthesized memberwise init for internal structs
enum PreferSynthesizedInitMode: Equatable, CustomStringConvertible {
    /// Never prefer synthesized init (default)
    case never
    /// Always prefer synthesized init for internal structs
    case always
    /// Prefer synthesized init only for structs conforming to specific protocols
    case conformances([String])

    init?(rawValue: String) {
        switch rawValue.lowercased() {
            case "never", "false":
                self = .never
            case "always", "true":
                self = .always
            default:
                // Parse as comma-separated list of conformances
                let conformances = rawValue.split(separator: ",").map {
                    String($0).trimmingCharacters(in: .whitespaces)
                }
                guard !conformances.isEmpty, conformances.allSatisfy({ !$0.isEmpty }) else {
                    return nil
                }
                self = .conformances(conformances)
        }
    }

    var rawValue: String {
        switch self {
            case .never:
                return "never"
            case .always:
                return "always"
            case let .conformances(list):
                return list.joined(separator: ",")
        }
    }

    var description: String {
        rawValue
    }
}

/// Configuration options for formatting. These aren't actually used by the
/// Formatter class itself, but it makes them available to the format rules.
package struct FormatOptions: CustomStringConvertible, @unchecked Sendable {
    var lineAfterMarks: Bool
    package var indent: String
    var linebreak: String
    var semicolons: SemicolonsMode
    var spaceAroundRangeOperators: OperatorSpacingMode
    var spaceAroundOperatorDeclarations: OperatorSpacingMode
    var useVoid: Bool
    var indentCase: Bool
    var trailingCommas: TrailingCommas
    var truncateBlankLines: Bool
    var insertBlankLines: Bool
    var removeBlankLines: Bool
    var allmanBraces: Bool
    var fileHeader: FileHeaderMode
    var ifdefIndent: IndentMode
    var wrapArguments: WrapMode
    var wrapParameters: WrapMode
    var wrapCollections: WrapMode
    var wrapTypealiases: WrapMode
    var wrapEnumCases: WrapEnumCases
    var closingParenPosition: ClosingParenPosition
    var callSiteClosingParenPosition: ClosingParenPosition
    var wrapReturnType: WrapReturnType
    var wrapConditions: WrapMode
    var wrapTernaryOperators: TernaryOperatorWrapMode
    var wrapStringInterpolation: StringInterpolationWrapMode
    var uppercaseHex: Bool
    var uppercaseExponent: Bool
    var decimalGrouping: Grouping
    var binaryGrouping: Grouping
    var octalGrouping: Grouping
    var hexGrouping: Grouping
    var fractionGrouping: Bool
    var exponentGrouping: Bool
    var hoistPatternLet: Bool
    var stripUnusedArguments: ArgumentStrippingMode
    var elsePosition: ElsePosition
    var guardElsePosition: GuardElsePosition
    var explicitSelf: SelfMode
    var selfRequired: Set<String>
    var throwCapturing: Set<String>
    var asyncCapturing: Set<String>
    var experimentalRules: Bool
    var importGrouping: ImportGrouping
    var trailingClosures: Set<String>
    var neverTrailing: Set<String>
    var xcodeIndentation: Bool
    var tabWidth: Int
    package var maxWidth: Int
    var smartTabs: Bool
    var assetLiteralWidth: AssetLiteralWidth
    var noSpaceOperators: Set<String>
    var noWrapOperators: Set<String>
    var modifierOrder: [String]
    var shortOptionals: OptionalsMode
    var funcAttributes: AttributeMode
    var typeAttributes: AttributeMode
    var varAttributes: AttributeMode
    var storedVarAttributes: AttributeMode
    var computedVarAttributes: AttributeMode
    var complexAttributes: AttributeMode
    var complexAttributesExceptions: Set<String>
    var markTypes: MarkMode
    var typeMarkComment: String
    var markExtensions: MarkMode
    var extensionMarkComment: String
    var groupedExtensionMarkComment: String
    var markCategories: Bool
    var categoryMarkComment: String
    var beforeMarks: Set<String>
    var lifecycleMethods: Set<String>
    var organizeTypes: Set<String>
    var organizeClassThreshold: Int
    var organizeStructThreshold: Int
    var organizeEnumThreshold: Int
    var organizeExtensionThreshold: Int
    var markStructThreshold: Int
    var markClassThreshold: Int
    var markEnumThreshold: Int
    var markExtensionThreshold: Int
    var organizationMode: DeclarationOrganizationMode
    var typeBodyMarks: TypeBodyMarks
    var visibilityOrder: [String]?
    var typeOrder: [String]?
    var customVisibilityMarks: Set<String>
    var customTypeMarks: Set<String>
    var blankLineAfterSubgroups: Bool
    var alphabeticallySortedDeclarationPatterns: Set<String>
    var swiftUIPropertiesSortMode: SwiftUIPropertiesSortMode
    var yodaSwap: YodaMode
    var extensionACLPlacement: ExtensionACLPlacement
    var propertyTypes: PropertyTypes
    var preservedPropertyTypes: Set<String>
    var inferredTypesInConditionalExpressions: Bool
    var emptyBracesSpacing: EmptyBracesSpacing
    var acronyms: Set<String>
    var preserveAcronyms: Set<String>
    var indentStrings: Bool
    var closureVoidReturn: ClosureVoidReturn
    var enumNamespaces: EnumNamespacesMode
    var typeBlankLines: TypeBlankLines
    var genericTypes: String
    var useSomeAny: Bool
    var wrapEffects: WrapEffects
    var preserveAnonymousForEach: Bool
    var preserveSingleLineForEach: Bool
    var preserveDocComments: Bool
    var conditionalAssignmentOnlyAfterNewProperties: Bool
    var typeDelimiterSpacing: DelimiterSpacing
    var initCoderNil: Bool
    var dateFormat: DateFormat
    var timeZone: FormatTimeZone
    var nilInit: NilInitType
    var preservedPrivateDeclarations: Set<String>
    var additionalXCTestSymbols: Set<String>
    var defaultTestSuiteAttributes: [String]
    var equatableMacro: EquatableMacro
    var urlMacro: URLMacro
    var preferFileMacro: Bool
    var lineBetweenConsecutiveGuards: Bool
    var blankLineAfterSwitchCase: BlankLineAfterSwitchCase
    var redundantThrows: RedundantEffectMode
    var redundantAsync: RedundantEffectMode
    var allowPartialWrapping: Bool
    var preferSynthesizedInitForInternalStructs: PreferSynthesizedInitMode

    /// Deprecated
    var indentComments: Bool

    /// Doesn't really belong here, but hard to put elsewhere
    var fragment: Bool
    var ignoreConflictMarkers: Bool
    package var swiftVersion: Version
    var languageMode: Version
    var fileInfo: FileInfo
    var markdownFiles: MarkdownFormattingMode
    var timeout: TimeInterval

    /// Enabled rules - this is a hack used to allow rules to vary their behavior
    /// based on other rules being enabled. Do not rely on it in other contexts
    var enabledRules: Set<String> = []

    package static let `default` = FormatOptions()

    init(
        lineAfterMarks: Bool = true,
        indent: String = "    ",
        linebreak: String = "\n",
        semicolons: SemicolonsMode = .inlineOnly,
        spaceAroundRangeOperators: OperatorSpacingMode = .insert,
        spaceAroundOperatorDeclarations: OperatorSpacingMode = .insert,
        useVoid: Bool = true,
        indentCase: Bool = false,
        trailingCommas: TrailingCommas = .always,
        indentComments: Bool = true,
        truncateBlankLines: Bool = true,
        insertBlankLines: Bool = true,
        removeBlankLines: Bool = true,
        allmanBraces: Bool = false,
        fileHeader: FileHeaderMode = .ignore,
        ifdefIndent: IndentMode = .indent,
        wrapArguments: WrapMode = .preserve,
        wrapParameters: WrapMode = .default,
        wrapCollections: WrapMode = .preserve,
        wrapTypealiases: WrapMode = .preserve,
        wrapEnumCases: WrapEnumCases = .always,
        closingParenPosition: ClosingParenPosition = .balanced,
        callSiteClosingParenPosition: ClosingParenPosition = .default,
        wrapReturnType: WrapReturnType = .preserve,
        wrapConditions: WrapMode = .preserve,
        wrapTernaryOperators: TernaryOperatorWrapMode = .default,
        wrapStringInterpolation: StringInterpolationWrapMode = .default,
        uppercaseHex: Bool = true,
        uppercaseExponent: Bool = false,
        decimalGrouping: Grouping = .group(3, 6),
        binaryGrouping: Grouping = .group(4, 8),
        octalGrouping: Grouping = .group(4, 8),
        hexGrouping: Grouping = .group(4, 8),
        fractionGrouping: Bool = false,
        exponentGrouping: Bool = false,
        hoistPatternLet: Bool = true,
        stripUnusedArguments: ArgumentStrippingMode = .all,
        elsePosition: ElsePosition = .sameLine,
        guardElsePosition: GuardElsePosition = .auto,
        explicitSelf: SelfMode = .remove,
        selfRequired: Set<String> = [],
        throwCapturing: Set<String> = [],
        asyncCapturing: Set<String> = [],
        experimentalRules: Bool = false,
        importGrouping: ImportGrouping = .alpha,
        trailingClosures: Set<String> = [],
        neverTrailing: Set<String> = [],
        xcodeIndentation: Bool = false,
        tabWidth: Int = 0,
        maxWidth: Int = 0,
        smartTabs: Bool = true,
        assetLiteralWidth: AssetLiteralWidth = .visualWidth,
        noSpaceOperators: Set<String> = [],
        noWrapOperators: Set<String> = [],
        modifierOrder: [String] = [],
        shortOptionals: OptionalsMode = .preserveStructInits,
        funcAttributes: AttributeMode = .preserve,
        typeAttributes: AttributeMode = .preserve,
        varAttributes: AttributeMode = .preserve,
        storedVarAttributes: AttributeMode = .preserve,
        computedVarAttributes: AttributeMode = .preserve,
        complexAttributes: AttributeMode = .preserve,
        complexAttributesExceptions: Set<String> = [],
        markTypes: MarkMode = .always,
        typeMarkComment: String = "MARK: - %t",
        markExtensions: MarkMode = .always,
        extensionMarkComment: String = "MARK: - %t + %c",
        groupedExtensionMarkComment: String = "MARK: %c",
        markCategories: Bool = true,
        categoryMarkComment: String = "MARK: %c",
        beforeMarks: Set<String> = [],
        lifecycleMethods: Set<String> = [],
        organizeTypes: Set<String> = ["class", "actor", "struct", "enum"],
        organizeClassThreshold: Int = 0,
        organizeStructThreshold: Int = 0,
        organizeEnumThreshold: Int = 0,
        organizeExtensionThreshold: Int = 0,
        markStructThreshold: Int = 0,
        markClassThreshold: Int = 0,
        markEnumThreshold: Int = 0,
        markExtensionThreshold: Int = 0,
        organizationMode: DeclarationOrganizationMode = .visibility,
        typeBodyMarks: TypeBodyMarks = .preserve,
        visibilityOrder: [String]? = nil,
        typeOrder: [String]? = nil,
        customVisibilityMarks: Set<String> = [],
        customTypeMarks: Set<String> = [],
        blankLineAfterSubgroups: Bool = true,
        alphabeticallySortedDeclarationPatterns: Set<String> = [],
        swiftUIPropertiesSortMode: SwiftUIPropertiesSortMode = .none,
        yodaSwap: YodaMode = .always,
        extensionACLPlacement: ExtensionACLPlacement = .onExtension,
        propertyTypes: PropertyTypes = .inferLocalsOnly,
        preservedPropertyTypes: Set<String> = ["Package"],
        inferredTypesInConditionalExpressions: Bool = false,
        emptyBracesSpacing: EmptyBracesSpacing = .noSpace,
        acronyms: Set<String> = ["ID", "URL", "UUID"],
        preserveAcronyms: Set<String> = [],
        indentStrings: Bool = false,
        closureVoidReturn: ClosureVoidReturn = .remove,
        enumNamespaces: EnumNamespacesMode = .always,
        typeBlankLines: TypeBlankLines = .remove,
        genericTypes: String = "",
        useSomeAny: Bool = true,
        wrapEffects: WrapEffects = .preserve,
        preserveAnonymousForEach: Bool = false,
        preserveSingleLineForEach: Bool = true,
        preserveDocComments: Bool = false,
        conditionalAssignmentOnlyAfterNewProperties: Bool = true,
        typeDelimiterSpacing: DelimiterSpacing = .spaceAfter,
        initCoderNil: Bool = false,
        dateFormat: DateFormat = .system,
        timeZone: FormatTimeZone = .system,
        nilInit: NilInitType = .remove,
        preservedPrivateDeclarations: Set<String> = [],
        additionalXCTestSymbols: Set<String> = [],
        defaultTestSuiteAttributes: [String] = [],
        equatableMacro: EquatableMacro = .none,
        urlMacro: URLMacro = .none,
        preferFileMacro: Bool = true,
        lineBetweenConsecutiveGuards: Bool = false,
        blankLineAfterSwitchCase: BlankLineAfterSwitchCase = .multilineOnly,
        redundantThrows: RedundantEffectMode = .testsOnly,
        redundantAsync: RedundantEffectMode = .testsOnly,
        allowPartialWrapping: Bool = true,
        preferSynthesizedInitForInternalStructs: PreferSynthesizedInitMode = .never,
        // Doesn't really belong here, but hard to put elsewhere
        fragment: Bool = false,
        ignoreConflictMarkers: Bool = false,
        swiftVersion: Version = .undefined,
        languageMode: Version? = nil,
        fileInfo: FileInfo = FileInfo(),
        markdownFiles: MarkdownFormattingMode = .ignore,
        timeout: TimeInterval = 1,
    ) {
        self.lineAfterMarks = lineAfterMarks
        self.indent = indent
        self.linebreak = linebreak
        self.semicolons = semicolons
        self.spaceAroundRangeOperators = spaceAroundRangeOperators
        self.spaceAroundOperatorDeclarations = spaceAroundOperatorDeclarations
        self.useVoid = useVoid
        self.indentCase = indentCase
        self.trailingCommas = trailingCommas
        self.truncateBlankLines = truncateBlankLines
        self.insertBlankLines = insertBlankLines
        self.removeBlankLines = removeBlankLines
        self.allmanBraces = allmanBraces
        self.fileHeader = fileHeader
        self.ifdefIndent = ifdefIndent
        self.wrapArguments = wrapArguments
        self.wrapParameters = wrapParameters
        self.wrapCollections = wrapCollections
        self.wrapTypealiases = wrapTypealiases
        self.wrapEnumCases = wrapEnumCases
        self.closingParenPosition = closingParenPosition
        self.callSiteClosingParenPosition = callSiteClosingParenPosition
        self.wrapReturnType = wrapReturnType
        self.wrapConditions = wrapConditions
        self.wrapTernaryOperators = wrapTernaryOperators
        self.wrapStringInterpolation = wrapStringInterpolation
        self.uppercaseHex = uppercaseHex
        self.uppercaseExponent = uppercaseExponent
        self.decimalGrouping = decimalGrouping
        self.fractionGrouping = fractionGrouping
        self.exponentGrouping = exponentGrouping
        self.binaryGrouping = binaryGrouping
        self.octalGrouping = octalGrouping
        self.hexGrouping = hexGrouping
        self.hoistPatternLet = hoistPatternLet
        self.stripUnusedArguments = stripUnusedArguments
        self.elsePosition = elsePosition
        self.guardElsePosition = guardElsePosition
        self.explicitSelf = explicitSelf
        self.selfRequired = selfRequired
        self.throwCapturing = throwCapturing
        self.asyncCapturing = asyncCapturing
        self.experimentalRules = experimentalRules
        self.importGrouping = importGrouping
        self.trailingClosures = trailingClosures
        self.neverTrailing = neverTrailing
        self.xcodeIndentation = xcodeIndentation
        self.tabWidth = tabWidth
        self.maxWidth = maxWidth
        self.smartTabs = smartTabs
        self.assetLiteralWidth = assetLiteralWidth
        self.noSpaceOperators = noSpaceOperators
        self.noWrapOperators = noWrapOperators
        self.modifierOrder = modifierOrder
        self.shortOptionals = shortOptionals
        self.funcAttributes = funcAttributes
        self.typeAttributes = typeAttributes
        self.varAttributes = varAttributes
        self.storedVarAttributes = storedVarAttributes
        self.computedVarAttributes = computedVarAttributes
        self.complexAttributes = complexAttributes
        self.complexAttributesExceptions = complexAttributesExceptions
        self.markTypes = markTypes
        self.typeMarkComment = typeMarkComment
        self.markExtensions = markExtensions
        self.extensionMarkComment = extensionMarkComment
        self.groupedExtensionMarkComment = groupedExtensionMarkComment
        self.markCategories = markCategories
        self.categoryMarkComment = categoryMarkComment
        self.beforeMarks = beforeMarks
        self.lifecycleMethods = lifecycleMethods
        self.organizeTypes = organizeTypes
        self.organizeClassThreshold = organizeClassThreshold
        self.organizeStructThreshold = organizeStructThreshold
        self.organizeEnumThreshold = organizeEnumThreshold
        self.organizeExtensionThreshold = organizeExtensionThreshold
        self.markStructThreshold = markStructThreshold
        self.markClassThreshold = markClassThreshold
        self.markEnumThreshold = markEnumThreshold
        self.markExtensionThreshold = markExtensionThreshold
        self.organizationMode = organizationMode
        self.typeBodyMarks = typeBodyMarks
        self.visibilityOrder = visibilityOrder
        self.typeOrder = typeOrder
        self.customVisibilityMarks = customVisibilityMarks
        self.customTypeMarks = customTypeMarks
        self.blankLineAfterSubgroups = blankLineAfterSubgroups
        self.alphabeticallySortedDeclarationPatterns = alphabeticallySortedDeclarationPatterns
        self.swiftUIPropertiesSortMode = swiftUIPropertiesSortMode
        self.yodaSwap = yodaSwap
        self.extensionACLPlacement = extensionACLPlacement
        self.propertyTypes = propertyTypes
        self.preservedPropertyTypes = preservedPropertyTypes
        self.inferredTypesInConditionalExpressions = inferredTypesInConditionalExpressions
        self.emptyBracesSpacing = emptyBracesSpacing
        self.acronyms = acronyms
        self.preserveAcronyms = preserveAcronyms
        self.indentStrings = indentStrings
        self.closureVoidReturn = closureVoidReturn
        self.enumNamespaces = enumNamespaces
        self.typeBlankLines = typeBlankLines
        self.genericTypes = genericTypes
        self.useSomeAny = useSomeAny
        self.wrapEffects = wrapEffects
        self.preserveAnonymousForEach = preserveAnonymousForEach
        self.preserveSingleLineForEach = preserveSingleLineForEach
        self.preserveDocComments = preserveDocComments
        self
            .conditionalAssignmentOnlyAfterNewProperties =
            conditionalAssignmentOnlyAfterNewProperties
        self.typeDelimiterSpacing = typeDelimiterSpacing
        self.initCoderNil = initCoderNil
        self.dateFormat = dateFormat
        self.timeZone = timeZone
        self.nilInit = nilInit
        self.preservedPrivateDeclarations = preservedPrivateDeclarations
        self.additionalXCTestSymbols = additionalXCTestSymbols
        self.defaultTestSuiteAttributes = defaultTestSuiteAttributes
        self.equatableMacro = equatableMacro
        self.urlMacro = urlMacro
        self.preferFileMacro = preferFileMacro
        self.lineBetweenConsecutiveGuards = lineBetweenConsecutiveGuards
        self.blankLineAfterSwitchCase = blankLineAfterSwitchCase
        self.redundantThrows = redundantThrows
        self.redundantAsync = redundantAsync
        self.allowPartialWrapping = allowPartialWrapping
        self.preferSynthesizedInitForInternalStructs = preferSynthesizedInitForInternalStructs
        self.indentComments = indentComments
        self.fragment = fragment
        self.ignoreConflictMarkers = ignoreConflictMarkers
        self.swiftVersion = swiftVersion
        self.languageMode = languageMode ?? defaultLanguageMode(for: swiftVersion)
        self.fileInfo = fileInfo
        self.markdownFiles = markdownFiles
        self.timeout = timeout
    }

    var useTabs: Bool {
        indent.first == "\t"
    }

    var requiresFileInfo: Bool {
        let string = fileHeader.rawValue
        return string.contains("{created") || string.contains("{file")
    }

    var allOptions: [String: Any] {
        let pairs = Mirror(reflecting: self).children.map { ($0!, $1) }
        var options = Dictionary(pairs, uniquingKeysWith: { $1 })
        for key in ["fileInfo", "enabledRules", "timeout"] { // Special cases
            options[key] = nil
        }
        return options
    }

    package var description: String {
        let allowedCharacters = CharacterSet.newlines.inverted
        return Mirror(reflecting: self).children.compactMap { child in
            var value = child.value
            switch value {
                case let array as [String]:
                    value = array.joined(separator: ",")
                case let set as Set<String>:
                    value = set.sorted().joined(separator: ",")
                default:
                    break
            }
            return "\(value);".addingPercentEncoding(withAllowedCharacters: allowedCharacters)
        }.joined()
    }
}

/// When to remove redundant `throws` / `async` effects
enum RedundantEffectMode: String, CaseIterable {
    /// Only remove redundant effects from test functions (default)
    case testsOnly = "tests-only"
    /// Remove redundant effects from all functions (can cause additional warnings / errors)
    case always
}

enum MarkdownFormattingMode: String, CaseIterable {
    /// Swift code in markdown files is ignored (default)
    case ignore
    /// Errors in markdown code blocks are ignored
    case lenient
    /// Errors in markdown code blocks are reported
    case strict
}
