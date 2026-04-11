extension SwiftDeclarationKind {
  /// All declaration kinds that represent functions, methods, accessors, and subscripts
  static let functionKinds: Set<SwiftDeclarationKind> = [
    .functionAccessorAddress,
    .functionAccessorDidset,
    .functionAccessorGetter,
    .functionAccessorMutableaddress,
    .functionAccessorSetter,
    .functionAccessorWillset,
    .functionConstructor,
    .functionDestructor,
    .functionFree,
    .functionMethodClass,
    .functionMethodInstance,
    .functionMethodStatic,
    .functionOperator,
    .functionSubscript,
  ]

  /// All declaration kinds that represent named types (class, struct, enum, typealias, associated type)
  static let typeKinds: Set<SwiftDeclarationKind> = [
    .class,
    .struct,
    .typealias,
    .associatedtype,
    .enum,
  ]
}
