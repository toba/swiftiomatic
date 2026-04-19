/// Convenience accessors for layout setting types.
///
/// The authoritative list lives in ``ConfigurationRegistry/allSettingTypes`` (generated).
/// This enum provides filtered views used by ``Configuration`` and schema generators.
package enum LayoutRegistry {
    package static var all: [any LayoutRule.Type] { ConfigurationRegistry.allSettingTypes }

    /// Root-level settings (group == nil).
    package static var rootRules: [any LayoutRule.Type] {
        all.filter { $0.group == nil }
    }

    /// Rules belonging to a specific group.
    package static func rules(in group: ConfigurationGroup) -> [any LayoutRule.Type] {
        all.filter { $0.group == group }
    }
}
