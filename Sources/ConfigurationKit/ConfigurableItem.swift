/// A configurable item with a key, default value, and optional group membership.
///
/// Both syntax rules and layout settings conform to this protocol, unifying the
/// concept of "something in the configuration that has a key and a default."
package protocol ConfigurableItem: Groupable {
    /// The type of the default value for this item.
    associatedtype DefaultValue: Sendable

    /// The key used to identify this item in the configuration.
    static var key: String { get }

    /// The default value when not specified in the configuration file.
    static var defaultValue: DefaultValue { get }
}
