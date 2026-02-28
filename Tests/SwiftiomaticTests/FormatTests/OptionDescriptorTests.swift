import Testing
@testable import Swiftiomatic

@Suite struct OptionDescriptorTests {
    private typealias OptionArgumentMapping<T> = (optionValue: T, argumentValue: String)

    private func validateDescriptorThrowsOptionsError(_ descriptor: OptionDescriptor,
                                                      invalidArguments: String = "invalid",
                                                      testName: String = #function)
    {
        var options = FormatOptions.default
        do {
            try descriptor.toOptions(invalidArguments, &options)
            Issue.record("\(testName): Invalid format Throws")
        } catch {
            guard case FormatError.options = error else {
                Issue.record("\(testName): Throws a FormatError.options error")
                return
            }
        }
    }

    private func validateFromArguments<T: Equatable>(_ descriptor: OptionDescriptor,
                                                     keyPath: WritableKeyPath<FormatOptions, T>,
                                                     expectations: [OptionArgumentMapping<T>],
                                                     testName: String = #function)
    {
        var options = FormatOptions.default
        for expectation in expectations {
            do {
                try descriptor.toOptions(expectation.argumentValue, &options)
                #expect(options[keyPath: keyPath] == expectation.optionValue, "\(testName): Argument \(expectation.argumentValue) map to option \(expectation.optionValue)")
                try descriptor.toOptions(expectation.argumentValue.uppercased(), &options)
                #expect(options[keyPath: keyPath] == expectation.optionValue, "\(testName): Argument Uppercased \(expectation.argumentValue) map to option \(expectation.optionValue)")
                try descriptor.toOptions(expectation.argumentValue.capitalized, &options)
                #expect(options[keyPath: keyPath] == expectation.optionValue, "\(testName): Argument capitalized \(expectation.argumentValue) map to option \(expectation.optionValue)")
            } catch {
                Issue.record("\(testName): error: \(error)")
            }
        }
    }

    private func validateFromOptionalArguments<T: Equatable>(_ descriptor: OptionDescriptor,
                                                             keyPath: WritableKeyPath<FormatOptions, T>,
                                                             expectations: [OptionArgumentMapping<T>],
                                                             testCaseVariation: Bool = true,
                                                             testName: String = #function)
    {
        var options = FormatOptions.default
        for expectation in expectations {
            do {
                try descriptor.toOptions(expectation.argumentValue, &options)
                #expect(options[keyPath: keyPath] == expectation.optionValue, "\(testName): Argument \(expectation.argumentValue) map to option \(String(describing: expectation.optionValue))")
                if testCaseVariation {
                    do {
                        try descriptor.toOptions(expectation.argumentValue.uppercased(), &options)
                        #expect(options[keyPath: keyPath] == expectation.optionValue, "\(testName): Argument Uppercased \(expectation.argumentValue) map to option \(String(describing: expectation.optionValue))")
                        try descriptor.toOptions(expectation.argumentValue.capitalized, &options)
                        #expect(options[keyPath: keyPath] == expectation.optionValue, "\(testName): Argument capitalized \(expectation.argumentValue) map to option \(String(describing: expectation.optionValue))")
                    } catch {
                        Issue.record("\(testName): error: \(error)")
                    }
                }
            } catch {
                Issue.record("\(testName): error: \(error)")
            }
        }
    }

    /// Validate From FormatOptions to Argument String
    ///
    /// - Parameters:
    ///   - descriptor: OptionDescriptor being tested
    ///   - keyPath: to the FormatOptions property that is being validated
    ///   - expectations: Array of expectations for different inputs
    ///   - invalid: Invalid FormatOptions value, which should yield the defaultArgument value
    ///   - testName: for assertion clarity
    private func validateFromOptions<T>(_ descriptor: OptionDescriptor,
                                        keyPath: WritableKeyPath<FormatOptions, T>,
                                        expectations: [OptionArgumentMapping<T>],
                                        invalid: T? = nil,
                                        testName: String = #function)
    {
        var options = FormatOptions.default
        for item in expectations {
            options[keyPath: keyPath] = item.optionValue
            #expect(descriptor.fromOptions(options) == item.argumentValue, "\(testName): Option is transformed to argument")
        }

        if let invalid {
            options[keyPath: keyPath] = invalid
            #expect(descriptor.fromOptions(options) == descriptor.defaultArgument, "\(testName): invalid input return the default value")
        }
    }

    private typealias FreeTextValidationExpectation = (input: String, isValid: Bool)

    private func validateArgumentsFreeTextType(_ descriptor: OptionDescriptor,
                                               expectations: [FreeTextValidationExpectation],
                                               testName: String = #function)
    {
        for expectation in expectations {
            let isValid = descriptor.validateArgument(expectation.input)
            #expect(isValid == expectation.isValid, "\(testName): \(isValid) != \(expectation.isValid)")
        }
    }

    // MARK: All options

    @Test func allDescriptorsHaveCorrectKeypath() throws {
        let rulesFile = projectDirectory.appendingPathComponent("Sources/OptionDescriptor.swift")
        let rulesSource = try String(contentsOf: rulesFile, encoding: .utf8)
        let tokens = tokenize(rulesSource)
        let formatter = Formatter(tokens)
        formatter.forEach(.identifier("OptionDescriptor")) { i, _ in
            guard formatter.token(at: i + 1) == .startOfScope("("),
                  let endOfScope = formatter.endOfScope(at: i + 1),
                  !formatter.tokens[i ..< endOfScope].contains(.stringBody("deprecated")),
                  let nameIndex = formatter.index(of: .identifier, before: i),
                  case let .identifier(name) = formatter.tokens[nameIndex]
            else {
                return
            }
            guard let keypathIndex = formatter.tokens[i ..< endOfScope].firstIndex(of: .identifier(name)),
                  formatter.tokens[keypathIndex - 1].isOperator("."),
                  let prevToken = formatter.token(at: keypathIndex - 2),
                  [.operator("\\", .prefix), .identifier("FormatOptions")].contains(prevToken)
            else {
                Issue.record("Descriptor for \(name) has incorrect keyPath (must match descriptor name)")
                return
            }
        }
    }

    @Test func allDescriptorsHaveProperty() {
        let allProperties = Set(FormatOptions.default.allOptions.keys)
        for descriptor in Descriptors.all where !descriptor.isDeprecated {
            #expect(
                allProperties.contains(descriptor.propertyName),
                "FormatOptions doesn't have property named \(descriptor.propertyName)."
            )
        }
    }

    @Test func allPropertiesHaveDescriptor() {
        let allDescriptors = Set(Descriptors.all.map(\.propertyName))
        for property in FormatOptions.default.allOptions.keys {
            #expect(
                allDescriptors.contains(property),
                "Missing OptionDescriptor for FormatOptions.\(property) option."
            )
        }
    }

    @Test func indentation() {
        let descriptor = Descriptors.indent
        let validations: [FreeTextValidationExpectation] = [
            (input: "tab", isValid: true),
            (input: "tabbed", isValid: true),
            (input: "tabs", isValid: true),
            (input: "tAb", isValid: true),
            (input: "TabbeD", isValid: true),
            (input: "TABS", isValid: true),
            (input: "2", isValid: true),
            (input: "4", isValid: true),
            (input: "foo", isValid: false),
            (input: "4,5 6 7", isValid: false),
            (input: "", isValid: false),
            (input: " ", isValid: false),
        ]
        let fromOptionExpectations: [OptionArgumentMapping<String>] = [
            (optionValue: "\t", argumentValue: "tab"),
            (optionValue: " ", argumentValue: "1"),
            (optionValue: "1234", argumentValue: "4"),
        ]
        let fromArgumentExpectations: [OptionArgumentMapping<String>] = [
            (optionValue: "\t", argumentValue: "tabs"),
            (optionValue: "\t", argumentValue: "tab"),
            (optionValue: "\t", argumentValue: "tabbed"),
            (optionValue: "\t", argumentValue: "tabs"),
            (optionValue: " ", argumentValue: "1"),
            (optionValue: "    ", argumentValue: "4"),
        ]

        validateArgumentsFreeTextType(descriptor, expectations: validations)
        validateFromOptions(descriptor, keyPath: \FormatOptions.indent, expectations: fromOptionExpectations)
        validateFromArguments(descriptor, keyPath: \FormatOptions.indent, expectations: fromArgumentExpectations)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    @Test func fileHeader() {
        let descriptor = Descriptors.fileHeader
        let validations: [FreeTextValidationExpectation] = [
            (input: "tab", isValid: true),
            (input: "", isValid: true),
            (input: "// Bob \n\n// {year}\n", isValid: true),
            (input: "/*\n\n\n*/", isValid: true),
            (input: "\n\n\n", isValid: true),
        ]
        let fromOptionExpectations: [OptionArgumentMapping<FileHeaderMode>] = [
            (optionValue: "", argumentValue: "strip"),
            (optionValue: "// Header", argumentValue: "// Header"),
            (optionValue: .ignore, argumentValue: "ignore"),
            (optionValue: "/*\n\n\n*/", argumentValue: "/*\\n\\n\\n*/"),
        ]
        let fromArgumentExpectations: [OptionArgumentMapping<FileHeaderMode>] = [
            (optionValue: "", argumentValue: "strip"),
            (optionValue: "// Header", argumentValue: "// Header"),
            (optionValue: .ignore, argumentValue: "ignore"),
            (optionValue: "// {year}", argumentValue: "{year}"),
            (optionValue: "/*\n\n\n*/", argumentValue: "/*\\n\\n\\n*/"),
            (optionValue: "//\n//\n//\n//\n//", argumentValue: "\\n\\n\\n\\n"),
            (optionValue: "//\n//\n// a\n//\n//", argumentValue: "\\n\\na\\n\\n"),
            (optionValue: "//\n// a\n//\n// a\n//", argumentValue: "\\na\\n\\na\\n"),
            (optionValue: "// a\n//", argumentValue: "a\\n"),
            (optionValue: "//a\n//b", argumentValue: "//a\\n//b"),
        ]

        validateArgumentsFreeTextType(descriptor, expectations: validations)
        validateFromOptions(descriptor, keyPath: \FormatOptions.fileHeader, expectations: fromOptionExpectations)
        validateFromOptionalArguments(descriptor, keyPath: \FormatOptions.fileHeader, expectations: fromArgumentExpectations, testCaseVariation: false)
    }

    @Test func noSpaceOperators() {
        let descriptor = Descriptors.noSpaceOperators
        let validations: [FreeTextValidationExpectation] = [
            (input: "+", isValid: true),
            (input: "*", isValid: true),
            (input: "/", isValid: true),
            (input: "", isValid: true),
            (input: ":", isValid: true),
            (input: "foo", isValid: false),
            (input: ";", isValid: false),
            (input: "?", isValid: false),
        ]
        let fromOptionExpectations: [OptionArgumentMapping<Set<String>>] = [
            (optionValue: [], argumentValue: ""),
            (optionValue: ["*", "/"], argumentValue: "*,/"),
        ]
        validateFromOptions(descriptor, keyPath: \FormatOptions.noSpaceOperators, expectations: fromOptionExpectations)
        validateArgumentsFreeTextType(descriptor, expectations: validations)
        var options = FormatOptions()
        #expect(throws: Never.self) { try descriptor.toOptions("+,+", &options) }
    }

    @Test func noWrapOperators() {
        let descriptor = Descriptors.noWrapOperators
        let validations: [FreeTextValidationExpectation] = [
            (input: "+", isValid: true),
            (input: "*", isValid: true),
            (input: "/", isValid: true),
            (input: "", isValid: true),
            (input: ":", isValid: true),
            (input: "foo", isValid: false),
            (input: ";", isValid: true),
            (input: "?", isValid: true),
            (input: "try", isValid: false),
            (input: "as", isValid: true),
            (input: "as?", isValid: true),
            (input: "is", isValid: true),
            (input: "do", isValid: false),
        ]
        let fromOptionExpectations: [OptionArgumentMapping<Set<String>>] = [
            (optionValue: [], argumentValue: ""),
            (optionValue: ["*", "/"], argumentValue: "*,/"),
        ]
        validateFromOptions(descriptor, keyPath: \FormatOptions.noWrapOperators, expectations: fromOptionExpectations)
        validateArgumentsFreeTextType(descriptor, expectations: validations)
        var options = FormatOptions()
        #expect(throws: Never.self) { try descriptor.toOptions("+,+", &options) }
    }

    @Test func modifierOrder() {
        let descriptor = Descriptors.modifierOrder
        var options = FormatOptions()
        let swiftLintDefaults = "override,acl,setterACL,dynamic,mutators,lazy,final,required,convenience,typeMethods,owned"
        #expect(throws: Never.self) { try descriptor.toOptions(swiftLintDefaults, &options) }
    }

    @Test func visibilityOrder() {
        let argument = "instanceLifecycle, beforeMarks, open, public, package, internal, private, fileprivate"

        let descriptor = Descriptors.visibilityOrder
        var options = FormatOptions()
        #expect(throws: Never.self) { try descriptor.toOptions(argument, &options) }
    }

    @Test func visibilityOrderUnparseableArgument() {
        let argument = "_instanceLifecycle, lifecycle, open, public, package, internal, private, fileprivate"

        let descriptor = Descriptors.visibilityOrder
        var options = FormatOptions()
        #expect(throws: (any Error).self) { try descriptor.toOptions(argument, &options) }
    }

    @Test func visibilityOrderMissingEssentials() {
        let argument = "beforemarks, lifecycle, open, public, internal, private, fileprivate"

        let descriptor = Descriptors.visibilityOrder
        var options = FormatOptions()
        #expect(throws: (any Error).self) { try descriptor.toOptions(argument, &options) }
    }

    @Test func typeOrder() {
        let argument = "beforeMarks, nestedType, instanceProperty, instanceLifecycle, instanceMethod"

        let descriptor = Descriptors.typeOrder
        var options = FormatOptions()
        #expect(throws: Never.self) { try descriptor.toOptions(argument, &options) }
    }

    @Test func typeOrderUnparseableArgument() {
        let argument = "_beforeMarks, nestedType, instanceProperty, instanceLifecycle, instanceMethod"

        let descriptor = Descriptors.typeOrder
        var options = FormatOptions()
        #expect(throws: (any Error).self) { try descriptor.toOptions(argument, &options) }
    }

    @Test func acceptsAirbnbSwiftStyleGuideVisibilityOrder() {
        // The `visibilityorder` configuration used in Airbnb's Swift Style Guide,
        // as defined here: https://github.com/airbnb/swift#subsection-organization
        let argument = "beforeMarks,instanceLifecycle,open,public,package,internal,private,fileprivate"

        let descriptor = Descriptors.visibilityOrder
        var options = FormatOptions()
        #expect(throws: Never.self) { try descriptor.toOptions(argument, &options) }
    }

    @Test func acceptsAirbnbSwiftStyleGuideTypeOrder() {
        // The `typeorder` configuration used in Airbnb's Swift Style Guide,
        // as defined here: https://github.com/airbnb/swift#subsection-organization
        let argument = "nestedType,staticProperty,staticPropertyWithBody,classPropertyWithBody,instanceProperty,instancePropertyWithBody,staticMethod,classMethod,instanceMethod"

        let descriptor = Descriptors.typeOrder
        var options = FormatOptions()
        #expect(throws: Never.self) { try descriptor.toOptions(argument, &options) }
    }

    @Test func formatOptionsDescriptionConsistency() {
        let options1 = FormatOptions(selfRequired: ["foo", "bar", "baz"])
        let options2 = FormatOptions(selfRequired: ["baz", "bar", "foo"])
        #expect(options1.description == options2.description)
    }

    @Test func fileMacroCase() {
        let argument = "#fileID"
        var options: FormatOptions = .default
        #expect(throws: Never.self) { try Descriptors.preferFileMacro.toOptions(argument, &options) }
    }
}
