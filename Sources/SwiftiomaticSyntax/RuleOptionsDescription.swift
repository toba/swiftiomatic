import Foundation

// sm:disable file_length

/// A type that can be converted into a human-readable representation.
public protocol Documentable {
  /// Indicate if the item has some content that is useful to document.
  var hasContent: Bool { get }

  /// Convert an object to Markdown.
  ///
  /// - Returns: A Markdown string describing the object.
  func markdown() -> String

  /// Convert an object to a single line string.
  ///
  /// - Returns: A "one liner" describing the object.
  func oneLiner() -> String

  /// Convert an object to YAML as used in `.swiftiomatic.yaml`.
  ///
  /// - Returns: A YAML snippet that can be used in configuration files.
  func yaml() -> String
}

/// Description of a rule configuration.
public struct RuleOptionsDescription: Equatable, Sendable {
  fileprivate let options: [RuleOptionsEntry]

  fileprivate init(options: [RuleOptionsEntry], exclusiveOptions: Set<String> = []) {
    if options.contains(.noOptions) {
      if options.count > 1 {
        Console.fatalError(
          """
          Cannot create a configuration description with a mixture of `noOption`
          and other options or multiple `noOptions`s. If any, descriptions must only
          contain one single no-documentation marker.
          """,
        )
      }
      self.options = []
      return
    }
    let nonEmptyOptions = options.filter { $0.value != .empty }
    self.options =
      exclusiveOptions.isEmpty
      ? nonEmptyOptions
      : nonEmptyOptions.filter { exclusiveOptions.contains($0.key) }
  }

  package static func from(configuration: some RuleOptions, exclusiveOptions: Set<String> = [])
    -> Self
  {
    // Prefer custom descriptions.
    if let customDescription = configuration.parameterDescription {
      return Self(options: customDescription.options, exclusiveOptions: exclusiveOptions)
    }
    let options: [RuleOptionsEntry] = Mirror(reflecting: configuration).children
      .flatMap { child in
        // Property wrappers have names prefixed by an underscore.
        if child.label?.starts(with: "_") == true,
          let element = child.value as? any AnyOptionElement
        {
          return element.description.options
        }
        return []
      }
    guard options.isNotEmpty else {
      Console.fatalError(
        """
        Rule configuration '\(configuration)' does not have any parameters.
        A custom description must be provided. If really no documentation is
        required, define the description as `{ RuleOptionsEntry.noOptions }`.
        """,
      )
    }
    return Self(options: options, exclusiveOptions: exclusiveOptions)
  }

  package func allowedKeys() -> [String] {
    options.flatMap { option -> [String] in
      switch option.value {
      case .nested(let nestedConfiguration) where option.key.isEmpty:
        nestedConfiguration.allowedKeys()
      case .empty:
        []
      default:
        [option.key]
      }
    }
  }
}

extension RuleOptionsDescription: Documentable {
  public var hasContent: Bool {
    options.isNotEmpty
  }

  public func oneLiner() -> String {
    oneLiner(separator: ";")
  }

  fileprivate func oneLiner(separator: String) -> String {
    options.map { $0.oneLiner() }.joined(separator: "\(separator) ")
  }

  public func markdown() -> String {
    guard hasContent else {
      return ""
    }
    return """
      <table>
      <thead>
      <tr><th>Key</th><th>Value</th></tr>
      </thead>
      <tbody>
      \(options.map { $0.markdown() }.joined(separator: "\n"))
      </tbody>
      </table>
      """
  }

  public func yaml() -> String {
    options.map { $0.yaml() }.joined(separator: "\n")
  }
}

/// A single option of a ``RuleOptionsDescription``.
package struct RuleOptionsEntry: Equatable, Sendable {
  /// An option serving as a marker for an empty configuration description.
  package static let noOptions = Self(key: "<nothing>", value: .empty)

  fileprivate let key: String
  fileprivate let value: OptionType
}

extension RuleOptionsEntry: Documentable {
  package var hasContent: Bool {
    self != .noOptions
  }

  package func markdown() -> String {
    """
    <tr>
    <td>
    \(key)
    </td>
    <td>
    \(value.markdown())
    </td>
    </tr>
    """
  }

  package func oneLiner() -> String {
    "\(key): \(value.oneLiner())"
  }

  package func yaml() -> String {
    if case .nested = value {
      return """
        \(key):
        \(value.yaml().indent(by: 2))
        """
    }
    return "\(key): \(value.yaml())"
  }
}

/// Type of an option.
package enum OptionType: Equatable, Sendable {
  /// An irrelevant option. It will be ignored in documentation serialization.
  case empty
  /// A boolean flag.
  case flag(Bool)
  /// A string option.
  case string(String)
  /// Like a string option but without quotes in the serialized output.
  case symbol(String)
  /// An integer option.
  case integer(Int)
  /// A floating point number option.
  case float(Double)
  /// Special option for a ``Severity``.
  case severity(Severity)
  /// A list of options.
  case list([Self])
  /// An option which is another set of configuration options to be nested in the serialized output.
  case nested(RuleOptionsDescription)
}

extension OptionType: Documentable {
  package var hasContent: Bool {
    self != .empty
  }

  package func markdown() -> String {
    switch self {
    case .empty, .flag, .symbol, .integer, .float, .severity:
      return yaml()
    case .string(let value):
      return "&quot;" + value + "&quot;"
    case .list(let options):
      return "[" + options.map { $0.markdown() }.joined(separator: ", ") + "]"
    case .nested(let value):
      return value.markdown()
    }
  }

  package func oneLiner() -> String {
    if case .nested(let value) = self {
      return value.oneLiner(separator: ",")
    }
    return yaml()
  }

  package func yaml() -> String {
    switch self {
    case .empty:
      Console.fatalError("Empty options shall not be serialized.")
    case .flag(let value):
      return String(describing: value)
    case .string(let value):
      return "\"" + value + "\""
    case .symbol(let value):
      return value
    case .integer(let value):
      return String(describing: value)
    case .float(let value):
      return String(describing: value)
    case .severity(let value):
      return value.rawValue
    case .list(let options):
      return "[" + options.map { $0.oneLiner() }.joined(separator: ", ") + "]"
    case .nested(let value):
      return value.yaml()
    }
  }
}

// MARK: Result builder

/// A result builder creating configuration descriptions.
@resultBuilder
package enum RuleOptionsDescriptionBuilder {
  /// :nodoc:
  package typealias Description = RuleOptionsDescription

  /// :nodoc:
  package static func buildBlock(_ components: Description...) -> Description {
    buildArray(components)
  }

  /// :nodoc:
  package static func buildOptional(_ component: Description?) -> Description {
    component ?? Description(options: [])
  }

  /// :nodoc:
  package static func buildEither(first component: Description) -> Description {
    component
  }

  /// :nodoc:
  package static func buildEither(second component: Description) -> Description {
    component
  }

  /// :nodoc:
  package static func buildExpression(_ expression: RuleOptionsEntry) -> Description {
    Description(options: [expression])
  }

  /// :nodoc:
  package static func buildExpression(_ expression: some RuleOptions) -> Description {
    Description.from(configuration: expression)
  }

  /// :nodoc:
  package static func buildArray(_ components: [Description]) -> Description {
    Description(options: components.flatMap(\.options))
  }
}

infix operator => : MultiplicationPrecedence

extension OptionType {
  /// Operator enabling an easy way to create a configuration option.
  ///
  /// - Parameters:
  ///   - key: Name of the option.
  ///   - value: Value of the option.
  ///
  /// - Returns: A configuration option built up by the given data.
  package static func => (key: String, value: OptionType) -> RuleOptionsEntry {
    RuleOptionsEntry(key: key, value: value)
  }

  /// Create an option defined by nested configuration description.
  ///
  /// - Parameters:
  ///   - description: A configuration description buildable by applying the result builder syntax.
  ///
  /// - Returns: A configuration option with a value being another configuration description.
  package static func nest(
    @RuleOptionsDescriptionBuilder _ description: () -> RuleOptionsDescription,
  ) -> Self {
    .nested(description())
  }
}

// MARK: Property wrapper

/// Type of a configuration parameter wrapper.
private protocol AnyOptionElement {
  var description: RuleOptionsDescription { get }
}

/// Type of an object that can be used as a configuration element.
package protocol AcceptableByOptionElement {
  /// Initializer taking a value from a configuration to create an element of `Self`.
  ///
  /// - Parameters:
  ///   - value: Value from a configuration.
  ///   - ruleID: The rule's identifier in which context the configuration parsing runs.
  init(fromAny value: Any, context ruleID: String) throws(SwiftiomaticError)

  /// Make the object an option.
  ///
  /// - Returns: Option representing the object.
  func asOption() -> OptionType

  /// Make the object a description.
  ///
  /// - Parameters:
  ///   - key: Name of the option to be put into the description.
  ///
  /// - Returns: Configuration description of this object.
  func asDescription(with key: String) -> RuleOptionsDescription

  /// Update the object.
  ///
  /// - Parameters:
  ///   - value: New underlying data for the object.
  ///   - ruleID: The rule's identifier in which context the configuration parsing runs.
  mutating func apply(_ value: Any, ruleID: String) throws(SwiftiomaticError)
}

extension AcceptableByOptionElement where Self: RawRepresentable, RawValue == String {
  package func asOption() -> OptionType {
    .symbol(rawValue)
  }

  package init(fromAny value: Any, context ruleID: String) throws(SwiftiomaticError) {
    if let value = value as? String, let newSelf = Self(rawValue: value) {
      self = newSelf
    } else {
      throw .invalidConfiguration(ruleID: ruleID)
    }
  }
}

/// Default implementations which are shortcuts applicable for most of the types conforming to the protocol.
extension AcceptableByOptionElement {
  package func asDescription(with key: String) -> RuleOptionsDescription {
    RuleOptionsDescription(options: [key => asOption()])
  }

  package mutating func apply(_ value: Any, ruleID: String) throws(SwiftiomaticError) {
    self = try Self(fromAny: value, context: ruleID)
  }
}

/// An option type that can appear inlined into its using configuration.
///
/// The ``OptionElement`` must opt into this behavior. In this case, the option does not have a key. This is
/// almost exclusively useful for common ``RuleOptions``s that are used in many other rules as child
/// configurations.
///
/// > Warning: A type conforming to this protocol is assumed to throw an issue in its `apply` method only when it's
/// absolutely clear that there is an error in the YAML configuration passed in. Since it may be used in a nested
/// context and doesn't know about the outer configuration, it's not always clear if a certain key-value is really
/// unacceptable.
package protocol InlinableOption: AcceptableByOptionElement {}

/// A single parameter of a rule configuration.
///
/// Apply it to a simple (e.g. boolean) property like
/// ```swift
/// @OptionElement
/// var property = true
/// ```
/// to add a (boolean) option to a configuration. The name of the option will be inferred from the name of the property.
/// In this case, it's just `property`. CamelCase names will translated into snake_case, i.e. `myOption` is going to be
/// translated into `my_option` in the `.swiftiomatic.yaml` configuration file.
///
/// This mechanism may be overwritten with an explicitly set key:
/// ```swift
/// @OptionElement(key: "foo_bar")
/// var property = true
/// ```
///
/// If the wrapped element is an ``InlinableOption``, there are three ways to represent it in the documentation:
///
/// 1. It can be inlined into the parent configuration. For that, add the parameter `isInline: true`. E.g.
///    ```swift
///    @OptionElement(isInline: true)
///    var levels = SeverityLevelsConfiguration(warning: 1, error: 2)
///    ```
///    will be documented as a linear list:
///    ```
///    warning: 1
///    error: 2
///    ```
/// 2. It can be represented as a separate nested configuration. In this case, it must not have set the `isInline` flag to
/// `true`. E.g.
///    ```swift
///    @OptionElement
///    var levels = SeverityLevelsConfiguration(warning: 1, error: 2)
///    ```
///    will have a nested configuration section:
///    ```
///    levels: warning: 1
///            error: 2
///    ```
/// 3. As mentioned in the beginning, the implicit key inference mechanism can be overruled by specifying a `key` as in:
///    ```swift
///    @OptionElement(key: "foo")
///    var levels = SeverityLevelsConfiguration(warning: 1, error: 2)
///    ```
///    It will appear in the documentation as:
///    ```
///    foo: warning: 1
///         error: 2
///    ```
///
@propertyWrapper
package struct OptionElement<T: AcceptableByOptionElement & Equatable & Sendable>: Equatable,
  Sendable
{
  /// A deprecation notice.
  package enum DeprecationNotice: Sendable {
    /// Warning suggesting an alternative option.
    case suggestAlternative(ruleID: String, name: String)
  }

  /// Wrapped option value.
  package var wrappedValue: T {
    didSet {
      if case .suggestAlternative(let id, let name) = deprecationNotice {
        SwiftiomaticError.deprecatedConfigurationOption(
          ruleID: id,
          key: key,
          alternative: name,
        )
        .print()
      }
      if wrappedValue != oldValue {
        postprocessor(&wrappedValue)
      }
    }
  }

  /// The wrapper itself providing access to all its data. This field can only be accessed by the
  /// element's name prefixed with a `$`.
  package var projectedValue: Self {
    get { self }
    _modify { yield &self }
  }

  /// Name of this configuration entry.
  package var key: String

  /// Whether this configuration element will be inlined into its description.
  package let isInline: Bool

  private let deprecationNotice: DeprecationNotice?
  private let postprocessor: @Sendable (inout T) -> Void

  /// Default constructor.
  ///
  /// - Parameters:
  ///   - value: Value to be wrapped.
  ///   - key: Optional name of the option. If not specified, it will be inferred from the attributed property.
  ///   - deprecationNotice: An optional deprecation notice in case an option is outdated and/or has been replaced by
  ///                        an alternative.
  ///   - postprocessor: Function to be applied to the wrapped value after parsing to validate and modify it.
  @preconcurrency
  package init(
    wrappedValue value: T,
    key: String,
    deprecationNotice: DeprecationNotice? = nil,
    postprocessor: @escaping @Sendable (inout T) -> Void = { _ in },
  ) {
    // sm:disable:previous no_empty_block
    self.init(
      wrappedValue: value,
      key: key,
      isInline: false,
      deprecationNotice: deprecationNotice,
      postprocessor: postprocessor,
    )

    // Modify the set value immediately.
    postprocessor(&wrappedValue)
  }

  /// Constructor for optional values.
  ///
  /// It allows to skip explicit initialization of the property with `nil`.
  ///
  /// - Parameters:
  ///   - key: Optional name of the option. If not specified, it will be inferred from the attributed property.
  package init<Wrapped>(key: String) where T == Wrapped? {
    self.init(wrappedValue: nil, key: key, isInline: false)
  }

  /// Constructor for an ``InlinableOption`` without a key.
  ///
  /// - Parameters:
  ///   - value: Value to be wrapped.
  ///   - isInline: If `true`, the option will be handled as it would be part of its parent. All of its options
  ///               will be inlined. Otherwise, it will be treated as a normal nested configuration with its name
  ///               inferred from the name of the attributed property.
  package init(wrappedValue value: T, isInline: Bool) where T: InlinableOption {
    assert(isInline, "Only 'isInline: true' is allowed at the moment.")
    self.init(wrappedValue: value, key: "", isInline: isInline)
  }

  /// Constructor for an ``InlinableOption`` with a name. The configuration will explicitly not be inlined.
  ///
  /// - Parameters:
  ///   - value: Value to be wrapped.
  ///   - key: Name of the option.
  package init(wrappedValue value: T, key: String) where T: InlinableOption {
    self.init(wrappedValue: value, key: key, isInline: false)
  }

  private init(
    wrappedValue: T,
    key: String,
    isInline: Bool,
    deprecationNotice: DeprecationNotice? = nil,
    postprocessor: @escaping @Sendable (inout T) -> Void = { _ in },
  ) {
    // sm:disable:previous no_empty_block
    self.wrappedValue = wrappedValue
    self.key = key
    self.isInline = isInline
    self.deprecationNotice = deprecationNotice
    self.postprocessor = postprocessor
  }

  package static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.wrappedValue == rhs.wrappedValue && lhs.key == rhs.key
  }
}

extension OptionElement: AnyOptionElement {
  fileprivate var description: RuleOptionsDescription {
    wrappedValue.asDescription(with: key)
  }
}

// MARK: AcceptableByOptionElement conformances

/// Default `init(fromAny:context:)` for types where the YAML value maps directly to `Self` via casting.
private protocol DirectlyCastableOptionElement: AcceptableByOptionElement {}

extension DirectlyCastableOptionElement {
  package init(fromAny value: Any, context ruleID: String) throws(SwiftiomaticError) {
    guard let value = value as? Self else {
      throw .invalidConfiguration(ruleID: ruleID)
    }
    self = value
  }
}

extension Optional: AcceptableByOptionElement
where Wrapped: AcceptableByOptionElement {
  package func asOption() -> OptionType {
    self?.asOption() ?? .empty
  }

  package init(fromAny value: Any, context ruleID: String) throws(SwiftiomaticError) {
    self = try Wrapped(fromAny: value, context: ruleID)
  }
}

package struct Symbol: Equatable, AcceptableByOptionElement {
  package let value: String

  package func asOption() -> OptionType {
    .symbol(value)
  }

  package init(fromAny value: Any, context ruleID: String) throws(SwiftiomaticError) {
    guard let value = value as? String else {
      throw .invalidConfiguration(ruleID: ruleID)
    }
    self.value = value
  }
}

extension Bool: AcceptableByOptionElement, DirectlyCastableOptionElement {
  package func asOption() -> OptionType {
    .flag(self)
  }
}

extension String: AcceptableByOptionElement, DirectlyCastableOptionElement {
  package func asOption() -> OptionType {
    .string(self)
  }
}

extension Array: AcceptableByOptionElement where Element: AcceptableByOptionElement {
  package func asOption() -> OptionType {
    .list(map { $0.asOption() })
  }

  package init(fromAny value: Any, context ruleID: String) throws(SwiftiomaticError) {
    let values = value as? [Any] ?? [value]
    self = try values.map { value throws(SwiftiomaticError) in
      try Element(fromAny: value, context: ruleID)
    }
  }
}

extension Set: AcceptableByOptionElement
where Element: AcceptableByOptionElement & Comparable {
  package func asOption() -> OptionType {
    sorted().asOption()
  }

  package init(fromAny value: Any, context ruleID: String) throws(SwiftiomaticError) {
    self = try Set([Element](fromAny: value, context: ruleID))
  }
}

extension Int: AcceptableByOptionElement, DirectlyCastableOptionElement {
  package func asOption() -> OptionType {
    .integer(self)
  }
}

extension Double: AcceptableByOptionElement {
  package func asOption() -> OptionType {
    .float(self)
  }

  package init(fromAny value: Any, context ruleID: String) throws(SwiftiomaticError) {
    if let value = value as? Self {
      self = value
    } else if let value = value as? Int {
      self = Double(value)
    } else {
      throw .invalidConfiguration(ruleID: ruleID)
    }
  }
}

extension CachedRegex: AcceptableByOptionElement {
  package func asOption() -> OptionType {
    .string(pattern)
  }

  package init(fromAny value: Any, context ruleID: String) throws(SwiftiomaticError) {
    guard let value = value as? String else {
      throw .invalidConfiguration(ruleID: ruleID)
    }
    self = try .from(pattern: value, for: ruleID)
  }
}

// MARK: RuleOptions conformances

extension AcceptableByOptionElement where Self: RuleOptions {
  package func asOption() -> OptionType {
    .nested(.from(configuration: self))
  }

  package func asDescription(with key: String) -> RuleOptionsDescription {
    if key.isEmpty {
      return .from(configuration: self)
    }
    return RuleOptionsDescription(options: [key => asOption()])
  }

  package mutating func apply(_ value: Any, ruleID: String) throws(SwiftiomaticError) {
    if let dict = value as? [String: Any] {
      try apply(configuration: dict)
    } else {
      throw .invalidConfiguration(ruleID: ruleID)
    }
  }

  package init(fromAny _: Any, context _: String) throws(SwiftiomaticError) {
    throw .genericError("Do not call this initializer")
  }
}

extension SeverityOption {
  /// Severity configurations are special in that they shall not be nested when an option name is provided.
  /// Instead, their only option value must be used together with the option name.
  package func asDescription(with key: String) -> RuleOptionsDescription {
    let description = RuleOptionsDescription.from(configuration: self)
    if key.isEmpty {
      return description
    }
    guard let option = description.options.onlyElement?.value, case .symbol = option else {
      Console.fatalError(
        """
        Severity configurations must have exactly one option that is a violation severity.
        """,
      )
    }
    return RuleOptionsDescription(options: [key => option])
  }
}
