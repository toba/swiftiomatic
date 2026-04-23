//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import ArgumentParser

/// Collects the command line options that were passed to `sm` and dispatches to the
/// appropriate subcommand.
@main
struct SwiftiomaticCommand: ParsableCommand {
    nonisolated(unsafe) static var configuration = CommandConfiguration(
        commandName: "sm",
        abstract: "Format or lint Swift source code",
        subcommands: [
            Doctor.self,
            DumpConfiguration.self,
            Format.self,
            Lint.self,
            Update.self,
        ],
        defaultSubcommand: Format.self
    )

    @OptionGroup()
    var versionOptions: VersionOptions
}
