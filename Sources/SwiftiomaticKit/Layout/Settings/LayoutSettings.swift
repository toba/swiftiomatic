/// Convenience accessors for layout setting types.
///
/// The authoritative list lives in ``ConfigurationRegistry/allSettingTypes`` (generated).
/// This enum provides filtered views used by ``Configuration`` and schema generators.
package enum LayoutSettings {
    package static var all: [any LayoutDescriptor.Type] { ConfigurationRegistry.allSettingTypes }

    /// Root-level settings (group == nil).
    package static var rootSettings: [any LayoutDescriptor.Type] {
        all.filter { $0.group == nil }
    }

    /// Settings belonging to a specific group.
    package static func settings(in group: ConfigurationGroup) -> [any LayoutDescriptor.Type] {
        all.filter { $0.group == group }
    }
}
