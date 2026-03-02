struct DynamicInlineConfiguration: RuleConfiguration {
    let id = "dynamic_inline"
    let name = "Dynamic Inline"
    let summary = "Avoid using 'dynamic' and '@inline(__always)' together"
    var nonTriggeringExamples: [Example] {
        [
              Example("class C {\ndynamic func f() {}}"),
              Example("class C {\n@inline(__always) func f() {}}"),
              Example("class C {\n@inline(never) dynamic func f() {}}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("class C {\n@inline(__always) dynamic ↓func f() {}\n}"),
              Example("class C {\n@inline(__always) public dynamic ↓func f() {}\n}"),
              Example("class C {\n@inline(__always) dynamic internal ↓func f() {}\n}"),
              Example("class C {\n@inline(__always)\ndynamic ↓func f() {}\n}"),
              Example("class C {\n@inline(__always)\ndynamic\n↓func f() {}\n}"),
            ]
    }
}
