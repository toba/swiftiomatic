import SwiftUI
import Swiftiomatic

struct OptionsTab: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        Form {
            Section("Configuration File") {
                LabeledContent("Path") {
                    if let path = model.configPath {
                        Text(path)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.head)
                    } else {
                        Text("No configuration file selected")
                            .foregroundStyle(.tertiary)
                    }
                }
                Button("Choose...") {
                    model.selectConfigFile()
                }
            }

            Section("Format") {
                Picker("Indentation", selection: Binding(
                    get: { model.configuration.formatIndent == "\t" ? "tabs" : "spaces" },
                    set: { newValue in
                        model.configuration.formatIndent = newValue == "tabs" ? "\t" : "    "
                        model.saveConfig()
                    }
                )) {
                    Text("Spaces").tag("spaces")
                    Text("Tabs").tag("tabs")
                }

                if model.configuration.formatIndent != "\t" {
                    Stepper(
                        "Indent Width: \(model.configuration.formatIndent.count)",
                        value: Binding(
                            get: { model.configuration.formatIndent.count },
                            set: { newValue in
                                model.configuration.formatIndent = String(repeating: " ", count: max(1, newValue))
                                model.saveConfig()
                            }
                        ),
                        in: 1 ... 8
                    )
                }

                Stepper(
                    "Max Line Width: \(model.configuration.formatMaxWidth)",
                    value: Binding(
                        get: { model.configuration.formatMaxWidth },
                        set: { newValue in
                            model.configuration.formatMaxWidth = newValue
                            model.saveConfig()
                        }
                    ),
                    in: 40 ... 200,
                    step: 10
                )
            }

            Section("Suggest") {
                Picker("Minimum Confidence", selection: Binding(
                    get: { model.configuration.suggestMinConfidence },
                    set: { newValue in
                        model.configuration.suggestMinConfidence = newValue
                        model.saveConfig()
                    }
                )) {
                    Text("Low").tag(Confidence.low)
                    Text("Medium").tag(Confidence.medium)
                    Text("High").tag(Confidence.high)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Options")
    }
}
