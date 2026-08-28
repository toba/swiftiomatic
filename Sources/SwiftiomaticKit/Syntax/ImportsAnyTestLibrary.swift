//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// The module names whose import marks a file as test code for the purposes of the test-gated rules
/// (`NoForceTry`, `NoForceUnwrap`, `NoImplicitlyUnwrappedOptionals`, `RequireCamelCaseIdentifiers`,
/// …).
///
/// Extensible: add a module here and every test-gated rule treats files importing it as test code.
let supportedTestLibraryModuleNames = ["XCTest", "Testing"]

/// A visitor that determines if the target source file imports a supported test library.
private final class ImportsAnyTestLibraryVisitor: SyntaxVisitor {
    private let context: Context

    init(context: Context) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        // If we already know whether or not a test library is imported, don't bother doing anything
        // else.
        guard context.importsAnyTestLibrary == .notDetermined else { return .skipChildren }

        // If the first import path component is a supported test-library module, record that fact.
        // Checking in this way lets us catch `import XCTest` but also specific decl imports like
        // `import class XCTest.XCTestCase`, if someone wants to do that. Imports nested inside
        // `#if` conditionals are covered too, since the visitor walks the entire tree.
        let firstComponent = node.path.first!.name.tokenKind
        if supportedTestLibraryModuleNames.contains(where: { firstComponent == .identifier($0) }) {
            context.importsAnyTestLibrary = .importsTestLibrary
        }

        return .skipChildren
    }

    override func visitPost(_: SourceFileSyntax) {
        // If we visited the entire source file and didn't find a supported test-library import,
        // record that fact.
        if context.importsAnyTestLibrary == .notDetermined {
            context.importsAnyTestLibrary = .doesNotImportTestLibrary
        }
    }
}

/// Sets the appropriate value of the `importsAnyTestLibrary` field in the context, which
/// approximates whether the file contains test code or not.
///
/// This setter will only run the visitor if another rule hasn't already called this function to
/// determine if the source file imports a supported test library.
///
/// - Parameters:
///   - context: The context information of the target source file.
///   - sourceFile: The file to be visited.
package func setImportsAnyTestLibrary(context: Context, sourceFile: SourceFileSyntax) {
    guard context.importsAnyTestLibrary == .notDetermined else { return }
    let visitor = ImportsAnyTestLibraryVisitor(context: context)
    visitor.walk(sourceFile)
}
