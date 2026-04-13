import SwiftUI
import SwiftiomaticSyntax

/// Tagged binding for a rule option, dispatching to the correct SwiftUI control
enum OptionBinding {
    case bool(Binding<Bool>)
    case int(Binding<Int>)
    case float(Binding<Double>)
    case string(Binding<String>, validValues: [String]? = nil)
}

/// Renders a single `ConfigOptionDescriptor` with the appropriate SwiftUI control
struct RuleOptionRow: View {
    let option: ConfigOptionDescriptor
    let binding: OptionBinding

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            control
            if !option.help.isEmpty {
                Text(option.help)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            //            if let defaultValue = option.defaultValue {
            //                Text("Default: \(defaultValue)")
            //                    .font(.caption2)
            //                    .foregroundStyle(.tertiary)
            //            }
        }
    }

    @ViewBuilder
    private var control: some View {
        switch binding {
        case .bool(let binding):
            Toggle(option.displayName, isOn: binding)

        case .int(let binding):
            HStack {
                Text(option.displayName)
                Spacer()
                if let defaultValue = option.defaultValue {
                    TextField(
                        defaultValue, value: binding, format: .number
                    )
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                }
                Stepper("", value: binding).labelsHidden()
            }

        case .float(let binding):
            HStack {
                Text(option.displayName)
                Spacer()
                if let defaultValue = option.defaultValue {
                    TextField(
                        defaultValue,
                        value: binding,
                        format: .number.precision(.fractionLength(0...2))
                    )
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                }
            }

        case .string(let binding, let validValues):
            if option.valueType == .severity {
                Picker(option.displayName, selection: binding) {
                    Text("Warning").tag("warning")
                    Text("Error").tag("error")
                }
            } else if let validValues, !validValues.isEmpty {
                Picker(option.displayName, selection: binding) {
                    ForEach(validValues, id: \.self) { value in
                        Text(value.replacingOccurrences(of: "_", with: " ").capitalized)
                            .tag(value)
                    }
                }
            } else if option.valueType == .list {
                HStack {
                    Text(option.displayName)
                    Spacer()
                    TextField("item1, item2", text: binding)
                        .frame(width: 200)
                        .textFieldStyle(.roundedBorder)
                }
            } else {
                HStack {
                    Text(option.displayName)
                    if let defaultValue = option.defaultValue {
                        Spacer()
                        TextField(defaultValue, text: binding)
                            .frame(width: 200)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Toggle") {
    RuleOptionRow(
        option: ConfigOptionDescriptor(
            key: "ignores_urls", displayName: "Ignores URLs",
            help: "Skip lines that only contain a URL",
            valueType: .bool, defaultValue: "false"
        ),
        binding: .bool(.constant(false))
    )
    .padding()
}

#Preview("Int Stepper") {
    RuleOptionRow(
        option: ConfigOptionDescriptor(
            key: "warning", displayName: "Warning",
            help: "Line length threshold for warnings",
            valueType: .int, defaultValue: "120"
        ),
        binding: .int(.constant(120))
    )
    .padding()
}

#Preview("Severity Picker") {
    RuleOptionRow(
        option: ConfigOptionDescriptor(
            key: "severity", displayName: "Severity", help: "",
            valueType: .severity, defaultValue: "warning"
        ),
        binding: .string(.constant("warning"))
    )
    .padding()
}

#Preview("Enum Picker") {
    RuleOptionRow(
        option: ConfigOptionDescriptor(
            key: "mode", displayName: "Mode", help: "Which declarations to check",
            valueType: .enum, defaultValue: "all_except_iboutlets",
            validValues: ["all", "all_except_iboutlets", "weak_except_iboutlets"]
        ),
        binding: .string(
            .constant("all_except_iboutlets"),
            validValues: ["all", "all_except_iboutlets", "weak_except_iboutlets"])
    )
    .padding()
}

