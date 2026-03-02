struct UnusedOptionalBindingConfiguration: RuleConfiguration {
    let id = "unused_optional_binding"
    let name = "Unused Optional Binding"
    let summary = "Prefer `!= nil` over `let _ =`"
    var nonTriggeringExamples: [Example] {
        [
              Example("if let bar = Foo.optionalValue {}"),
              Example("if let (_, second) = getOptionalTuple() {}"),
              Example("if let (_, asd, _) = getOptionalTuple(), let bar = Foo.optionalValue {}"),
              Example("if foo() { let _ = bar() }"),
              Example("if foo() { _ = bar() }"),
              Example("if case .some(_) = self {}"),
              Example("if let point = state.find({ _ in true }) {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("if let ↓_ = Foo.optionalValue {}"),
              Example("if let a = Foo.optionalValue, let ↓_ = Foo.optionalValue2 {}"),
              Example("guard let a = Foo.optionalValue, let ↓_ = Foo.optionalValue2 {}"),
              Example("if let (first, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue {}"),
              Example("if let (first, _) = getOptionalTuple(), let ↓_ = Foo.optionalValue {}"),
              Example("if let (_, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue {}"),
              Example("if let ↓(_, _, _) = getOptionalTuple(), let bar = Foo.optionalValue {}"),
              Example("func foo() { if let ↓_ = bar {} }"),
            ]
    }
}
