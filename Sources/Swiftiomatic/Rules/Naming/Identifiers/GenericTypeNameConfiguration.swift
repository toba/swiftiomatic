struct GenericTypeNameConfiguration: RuleConfiguration {
    let id = "generic_type_name"
    let name = "Generic Type Name"
    let summary = "Generic type name should only contain alphanumeric characters, start with an uppercase character and span between 1 and 20 characters in length."
    var nonTriggeringExamples: [Example] {
        [
              Example("func foo<T>() {}"),
              Example("func foo<T>() -> T {}"),
              Example("func foo<T, U>(param: U) -> T {}"),
              Example("func foo<T: Hashable, U: Rule>(param: U) -> T {}"),
              Example("struct Foo<T> {}"),
              Example("class Foo<T> {}"),
              Example("enum Foo<T> {}"),
              Example("func run(_ options: NoOptions<CommandantError<()>>) {}"),
              Example("func foo(_ options: Set<type>) {}"),
              Example("func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool"),
              Example(
                "func configureWith(data: Either<MessageThread, (project: Project, backing: Backing)>)",
              ),
              Example("typealias StringDictionary<T> = Dictionary<String, T>"),
              Example("typealias BackwardTriple<T1, T2, T3> = (T3, T2, T1)"),
              Example("typealias DictionaryOfStrings<T : Hashable> = Dictionary<T, String>"),
              Example("struct Foo<let count: Int> {}"),
              Example("struct Bar<let size: Int, T> {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("func foo<↓T_Foo>() {}"),
              Example("func foo<T, ↓U_Foo>(param: U_Foo) -> T {}"),
              Example("func foo<↓\(String(repeating: "T", count: 21))>() {}"),
              Example("func foo<↓type>() {}"),
              Example("typealias StringDictionary<↓T_Foo> = Dictionary<String, T_Foo>"),
              Example("typealias BackwardTriple<T1, ↓T2_Bar, T3> = (T3, T2_Bar, T1)"),
              Example("typealias DictionaryOfStrings<↓T_Foo: Hashable> = Dictionary<T_Foo, String>"),
            ]
    }
}
