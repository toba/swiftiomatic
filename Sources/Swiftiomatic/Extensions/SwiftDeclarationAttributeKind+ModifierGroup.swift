extension SwiftDeclarationAttributeKind {
    /// Attributes that imply an Objective-C runtime dependency (Foundation)
    static let attributesRequiringFoundation: Set<SwiftDeclarationAttributeKind> = [
        .objc,
        .objcName,
        .objcMembers,
        .objcNonLazyRealization,
    ]

    /// Logical grouping of declaration modifiers for ordering rules
    enum ModifierGroup: String, CustomDebugStringConvertible, Sendable {
        case override
        case acl
        case setterACL
        case owned
        case mutators
        case final
        case typeMethods
        case required
        case convenience
        case lazy
        case dynamic
        case isolation
        case atPrefixed

        /// Creates a modifier group from a raw SourceKit attribute string
        ///
        /// - Parameters:
        ///   - rawAttribute: The raw SourceKit attribute value (e.g. `"source.decl.attribute.public"`).
        init?(rawAttribute: String) {
            let allModifierGroups: Set<SwiftDeclarationAttributeKind.ModifierGroup> = [
                .acl, .setterACL, .mutators, .override, .owned, .atPrefixed, .dynamic, .final,
                .typeMethods,
                .required, .convenience, .lazy, .isolation,
            ]
            let modifierGroup = allModifierGroups.first {
                $0.swiftDeclarationAttributeKinds.contains(where: { $0.rawValue == rawAttribute })
            }

            if let modifierGroup {
                self = modifierGroup
            } else {
                return nil
            }
        }

        /// The set of ``SwiftDeclarationAttributeKind`` values belonging to this group
        var swiftDeclarationAttributeKinds: Set<SwiftDeclarationAttributeKind> {
            switch self {
                case .acl:
                    return [
                        .private,
                        .fileprivate,
                        .internal,
                        .public,
                        .open,
                    ]
                case .setterACL:
                    return [
                        .setterPrivate,
                        .setterFilePrivate,
                        .setterInternal,
                        .setterPublic,
                        .setterOpen,
                    ]
                case .mutators:
                    return [
                        .mutating,
                        .nonmutating,
                    ]
                case .override:
                    return [.override]
                case .owned:
                    return [.weak]
                case .final:
                    return [.final]
                case .typeMethods:
                    return []
                case .required:
                    return [.required]
                case .convenience:
                    return [.convenience]
                case .lazy:
                    return [.lazy]
                case .dynamic:
                    return [.dynamic]
                case .isolation:
                    return [.nonisolated]
                case .atPrefixed:
                    return [
                        .objc,
                        .nonobjc,
                        .objcMembers,
                        .ibaction,
                        .ibsegueaction,
                        .iboutlet,
                        .ibdesignable,
                        .ibinspectable,
                        .nsManaged,
                        .nsCopying,
                    ]
            }
        }

        var debugDescription: String {
            rawValue
        }
    }
}
