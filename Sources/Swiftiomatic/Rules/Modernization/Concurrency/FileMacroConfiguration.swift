struct FileMacroConfiguration: RuleConfiguration {
    let id = "file_macro"
    let name = "File Macro"
    let summary = "Prefer `#file` over `#fileID` (identical in Swift 6+)"
    let scope: Scope = .suggest
}
