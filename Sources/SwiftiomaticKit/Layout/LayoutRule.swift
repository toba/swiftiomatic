/// A self-describing pretty-print configuration setting.
///
/// Each layout descriptor is a single source of truth for its JSON key, group,
/// description, default value, and schema. ``Configuration`` derives its
/// encode/decode logic from these types, and schema generators read their
/// metadata directly.
///
/// Layout descriptors share two protocols with syntax rule configs:
/// - ``Groupable`` — optional ``ConfigGroup`` membership (also on ``Rule``)
/// - ``ConfigRepresentable`` — emit ``ConfigProperty`` for schema generation
///   (also on rule config structs like `SortImportsConfiguration`)
package protocol LayoutRule: Configurable {}
