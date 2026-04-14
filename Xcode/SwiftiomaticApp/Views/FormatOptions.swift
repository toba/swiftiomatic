import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax

struct FormatOptions: View {
    @Bindable var store: ConfigStore

    private var indentation: Binding<String> {
        Binding(
            get: { store.configuration.formatIndent == "\t" ? "tabs" : "spaces" },
            set: { newValue in
                store.configuration.formatIndent = newValue == "tabs" ? "\t" : "    "
            }
        )
    }

    private var indentWidth: Binding<Int> {
        Binding(
            get: { store.configuration.formatIndent.count },
            set: { newValue in
                store.configuration.formatIndent = String(repeating: " ", count: max(1, newValue))
            }
        )
    }

    private var maxLineWidth: Binding<Int> {
        Binding(
            get: { store.configuration.formatMaxWidth },
            set: { newValue in
                store.configuration.formatMaxWidth = newValue
            }
        )
    }

    private var minConfidence: Binding<Confidence> {
        Binding(
            get: { store.configuration.suggestMinConfidence },
            set: { newValue in
                store.configuration.suggestMinConfidence = newValue
            }
        )
    }

    var body: some View {
        Form {
            Section("Format") {
                Picker("Indentation", selection: indentation) {
                    Text("Spaces").tag("spaces")
                    Text("Tabs").tag("tabs")
                }

                if store.configuration.formatIndent != "\t" {
                    Stepper(
                        "Indent Width: \(store.configuration.formatIndent.count)",
                        value: indentWidth,
                        in: 1...8
                    )
                }

                Stepper(
                    "Max Line Width: \(store.configuration.formatMaxWidth)",
                    value: maxLineWidth,
                    in: 40...200,
                    step: 10
                )
            }

            Section("Suggest") {
                Picker("Minimum Confidence", selection: minConfidence) {
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
