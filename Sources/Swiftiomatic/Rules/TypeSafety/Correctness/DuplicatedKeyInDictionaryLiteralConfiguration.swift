struct DuplicatedKeyInDictionaryLiteralConfiguration: RuleConfiguration {
    let id = "duplicated_key_in_dictionary_literal"
    let name = "Duplicated Key in Dictionary Literal"
    let summary = "Dictionary literals with duplicated keys will crash at runtime"
}
