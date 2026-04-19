//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftParser
import SwiftSyntax

/// Scans `TokenStream+*.swift` extension files to discover visit methods that need
/// forwarding stubs in the generated `TokenStream` subclass.
package final class TokenStreamStubCollector {

    /// A single visit or visitPost method found in a TSC extension.
    struct DetectedStub: Comparable {
        /// The method name in the extension (e.g. "visitAccessorDeclList" or "visitPostFunctionCallExpr").
        let methodName: String

        /// The parameter label ("node" or "token").
        let paramLabel: String

        /// The parameter type (e.g. "AccessorDeclListSyntax" or "TokenSyntax").
        let paramType: String

        /// Whether this is a `visitPost` override (void return) vs a `visit` override.
        let isPost: Bool

        static func < (lhs: DetectedStub, rhs: DetectedStub) -> Bool {
            if lhs.isPost != rhs.isPost { return !lhs.isPost }
            return lhs.paramType < rhs.paramType
        }
    }

    /// All detected stubs, populated by `collect(from:)`.
    var stubs = [DetectedStub]()

    package init() {}

    /// Scans all `TokenStream+*.swift` files in the given directory for visit methods.
    package func collect(from directory: URL) throws {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: directory.path) else {
            fatalError("Could not list the directory \(directory.path)")
        }

        for baseName in enumerator {
            guard let baseName = baseName as? String,
                  baseName.hasPrefix("TokenStream+"),
                  baseName.hasSuffix(".swift")
            else { continue }

            let fileURL = directory.appendingPathComponent(baseName)
            let fileInput = try String(contentsOf: fileURL, encoding: .utf8)
            let sourceFile = Parser.parse(source: fileInput)

            for statement in sourceFile.statements {
                guard let extensionDecl = statement.item.as(ExtensionDeclSyntax.self) else {
                    continue
                }
                for member in extensionDecl.memberBlock.members {
                    if let stub = detectedStub(from: member) {
                        stubs.append(stub)
                    }
                }
            }
        }

        stubs.sort()
    }

    private func detectedStub(from member: MemberBlockItemSyntax) -> DetectedStub? {
        guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else { return nil }

        let name = funcDecl.name.text
        guard name.hasPrefix("visit") else { return nil }

        let params = funcDecl.signature.parameterClause.parameters
        guard let param = params.firstAndOnly else { return nil }

        guard let paramType = param.type.as(IdentifierTypeSyntax.self) else { return nil }
        let paramTypeName = paramType.name.text
        guard paramTypeName.hasSuffix("Syntax") else { return nil }

        // Distinguish visitPost (void return) from visit (returns SyntaxVisitorContinueKind).
        let hasReturn = funcDecl.signature.returnClause != nil
        let isPost = !hasReturn

        // Skip helper methods that happen to start with "visit" but aren't visitor overrides.
        // Visitor methods always have a single parameter whose type ends in "Syntax".
        let paramLabel = param.secondName?.text ?? param.firstName.text

        return DetectedStub(
            methodName: name,
            paramLabel: paramLabel,
            paramType: paramTypeName,
            isPost: isPost
        )
    }
}
