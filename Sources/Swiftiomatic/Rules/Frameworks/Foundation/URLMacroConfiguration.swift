struct URLMacroConfiguration: RuleConfiguration {
    let id = "url_macro"
    let name = "URL Macro"
    let summary = "Force-unwrapped `URL(string:)` can be replaced with a `#URL` macro"
    let scope: Scope = .suggest
}
