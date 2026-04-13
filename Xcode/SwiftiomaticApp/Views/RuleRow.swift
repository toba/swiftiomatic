import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax

struct RuleRow: View {
    @Bindable var document: SwiftiomaticDocument
    let entry: RuleConfigurationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                ScopeBadge(scope: entry.scope)

                Text(entry.name)
                    .fontWeight(.medium)

                if entry.isCorrectable {
                    Label("Auto-fixable", systemImage: "wand.and.stars")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.15), in: .capsule)
                        .foregroundStyle(.green)
                }

                Spacer()

                Toggle(isOn: document.ruleEnabledBinding(for: entry)) {
                    EmptyView()
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
            }

            Text(entry.id)
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)

            Text(entry.summary)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            if !entry.configurationOptions.isEmpty {
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(
                            Array(entry.configurationOptions.enumerated()),
                            id: \.element.key
                        ) { index, option in
                            if index > 0 { Divider() }
                            RuleOptionRow(
                                option: option,
                                binding: makeBinding(for: option)
                            )
                        }
                    }
                    .padding(4)
                }
                .padding(.top, 4)
                .disabled(!document.isRuleEnabled(entry))
            }
        }
    }

    // MARK: - Option Bindings

    private func ruleConfigDict() -> [String: ConfigValue] {
        if case .dictionary(let dict) = document.configuration.lintRuleConfigs[entry.id] {
            return dict
        }
        return [:]
    }

    private func setOption(_ key: String, value: ConfigValue?) {
        var dict = ruleConfigDict()
        if let value {
            dict[key] = value
        } else {
            dict.removeValue(forKey: key)
        }
        if dict.isEmpty {
            document.configuration.lintRuleConfigs.removeValue(forKey: entry.id)
        } else {
            document.configuration.lintRuleConfigs[entry.id] = .dictionary(dict)
        }
    }

    private func makeBinding(for option: ConfigOptionDescriptor) -> OptionBinding {
        switch option.valueType {
        case .bool:
            .bool(boolBinding(for: option))
        case .int:
            .int(intBinding(for: option))
        case .float:
            .float(doubleBinding(for: option))
        case .string:
            .string(stringBinding(for: option))
        case .severity:
            .string(stringBinding(for: option))
        case .enum:
            .string(stringBinding(for: option), validValues: option.validValues)
        case .list:
            .string(listBinding(for: option))
        }
    }

    private func boolBinding(for option: ConfigOptionDescriptor) -> Binding<Bool> {
        Binding(
            get: {
                if case .bool(let v) = ruleConfigDict()[option.key] { return v }
                return option.defaultValue == "true"
            },
            set: { newValue in
                let isDefault = String(newValue) == option.defaultValue
                setOption(option.key, value: isDefault ? nil : .bool(newValue))
            }
        )
    }

    private func intBinding(for option: ConfigOptionDescriptor) -> Binding<Int> {
        Binding(
            get: {
                if case .int(let v) = ruleConfigDict()[option.key] { return v }
                return Int(option.defaultValue) ?? 0
            },
            set: { newValue in
                let isDefault = String(newValue) == option.defaultValue
                setOption(option.key, value: isDefault ? nil : .int(newValue))
            }
        )
    }

    private func doubleBinding(for option: ConfigOptionDescriptor) -> Binding<Double> {
        Binding(
            get: {
                let dict = ruleConfigDict()
                if case .double(let v) = dict[option.key] { return v }
                if case .int(let v) = dict[option.key] { return Double(v) }
                return Double(option.defaultValue) ?? 0.0
            },
            set: { newValue in
                let isDefault = String(newValue) == option.defaultValue
                setOption(option.key, value: isDefault ? nil : .double(newValue))
            }
        )
    }

    private func stringBinding(for option: ConfigOptionDescriptor) -> Binding<String> {
        Binding(
            get: {
                if case .string(let v) = ruleConfigDict()[option.key] { return v }
                return option.defaultValue
            },
            set: { newValue in
                let isDefault = newValue == option.defaultValue
                setOption(option.key, value: isDefault ? nil : .string(newValue))
            }
        )
    }

    private func listBinding(for option: ConfigOptionDescriptor) -> Binding<String> {
        Binding(
            get: {
                if case .array(let items) = ruleConfigDict()[option.key] {
                    return items.compactMap {
                        if case .string(let s) = $0 { return s }
                        return nil
                    }.joined(separator: ", ")
                }
                return option.defaultValue
            },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty || trimmed == option.defaultValue {
                    setOption(option.key, value: nil)
                } else {
                    let items = trimmed.split(separator: ",")
                        .map { ConfigValue.string(String($0.trimmingCharacters(in: .whitespaces))) }
                        .filter { if case .string(let s) = $0 { !s.isEmpty } else { true } }
                    setOption(option.key, value: .array(items))
                }
            }
        )
    }
}

// MARK: - Preview Mocks

private let previewDocument = SwiftiomaticDocument()

private let previewLintRule = RuleConfigurationEntry(
    id: "line_length",
    name: "Line Length",
    summary: "Lines should not span too many characters.",
    rationale: "Long lines are harder to read and review in side-by-side diffs.",
    category: RuleCategory(name: "Metrics", subcategory: "Length"),
    scope: .lint,
    isCorrectable: true,
    configurationOptions: [
        ConfigOptionDescriptor(
            key: "warning", displayName: "Warning", help: "Threshold for warning severity",
            valueType: .int, defaultValue: "120"
        ),
        ConfigOptionDescriptor(
            key: "error", displayName: "Error", help: "Threshold for error severity",
            valueType: .int, defaultValue: "200"
        ),
        ConfigOptionDescriptor(
            key: "ignores_urls", displayName: "Ignores URLs", help: "Skip lines that only contain a URL",
            valueType: .bool, defaultValue: "false"
        ),
    ]
)

private let previewOptInRule = RuleConfigurationEntry(
    id: "explicit_type_interface",
    name: "Explicit Type Interface",
    summary: "Properties should have a type interface.",
    category: RuleCategory(name: "Style"),
    scope: .lint,
    isOptIn: true,
    configurationOptions: [
        ConfigOptionDescriptor(
            key: "severity", displayName: "Severity", help: "",
            valueType: .severity, defaultValue: "warning"
        )
    ]
)

private let previewFormatRule = RuleConfigurationEntry(
    id: "indent",
    name: "Indentation",
    summary: "Code should be consistently indented using the configured style.",
    category: RuleCategory(name: "Whitespace"),
    scope: .format,
    isCorrectable: true
)

private let previewSuggestRule = RuleConfigurationEntry(
    id: "swiftui_view_anti_patterns",
    name: "SwiftUI View Anti-Patterns",
    summary: "Detects common SwiftUI view body smells like large closures and unstable view trees.",
    category: RuleCategory(name: "SwiftUI"),
    scope: .suggest
)

#Preview("Lint Rule — Correctable") {
    RuleRow(document: previewDocument, entry: previewLintRule)
        .padding()
}

#Preview("Lint Rule — Opt-In") {
    RuleRow(document: previewDocument, entry: previewOptInRule)
        .padding()
}

#Preview("Format Rule") {
    RuleRow(document: previewDocument, entry: previewFormatRule)
        .padding()
}

#Preview("Suggest Rule") {
    RuleRow(document: previewDocument, entry: previewSuggestRule)
        .padding()
}

