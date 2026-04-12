import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax

struct FormatOptions: View {
    @Bindable var document: SwiftiomaticDocument

    private var indentation: Binding<String> {
        Binding(
            get: { document.configuration.formatIndent == "\t" ? "tabs" : "spaces" },
            set: { newValue in
                document.configuration.formatIndent = newValue == "tabs" ? "\t" : "    "
            }
        )
    }

    private var indentWidth: Binding<Int> {
        Binding(
            get: { document.configuration.formatIndent.count },
            set: { newValue in
                document.configuration.formatIndent = String(repeating: " ", count: max(1, newValue))
            }
        )
    }

    private var maxLineWidth: Binding<Int> {
        Binding(
            get: { document.configuration.formatMaxWidth },
            set: { newValue in
                document.configuration.formatMaxWidth = newValue
            }
        )
    }

    private var minConfidence: Binding<Confidence> {
        Binding(
            get: { document.configuration.suggestMinConfidence },
            set: { newValue in
                document.configuration.suggestMinConfidence = newValue
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

                if document.configuration.formatIndent != "\t" {
                    Stepper(
                        "Indent Width: \(document.configuration.formatIndent.count)",
                        value: indentWidth,
                        in: 1...8
                    )
                }

                Stepper(
                    "Max Line Width: \(document.configuration.formatMaxWidth)",
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

