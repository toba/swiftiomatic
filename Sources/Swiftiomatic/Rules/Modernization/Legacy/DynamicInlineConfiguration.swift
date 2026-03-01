struct DynamicInlineConfiguration: RuleConfiguration {
    let id = "dynamic_inline"
    let name = "Dynamic Inline"
    let summary = "Avoid using 'dynamic' and '@inline(__always)' together"
}
