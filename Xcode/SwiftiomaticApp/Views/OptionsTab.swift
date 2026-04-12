import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax
import UniformTypeIdentifiers

struct OptionsDetailView: View {
  @Environment(AppModel.self) private var model

  private var indentation: Binding<String> {
    Binding(
      get: { model.configuration.formatIndent == "\t" ? "tabs" : "spaces" },
      set: { newValue in
        model.configuration.formatIndent = newValue == "tabs" ? "\t" : "    "
        model.saveConfig()
      }
    )
  }

  private var indentWidth: Binding<Int> {
    Binding(
      get: { model.configuration.formatIndent.count },
      set: { newValue in
        model.configuration.formatIndent = String(repeating: " ", count: max(1, newValue))
        model.saveConfig()
      }
    )
  }

  private var maxLineWidth: Binding<Int> {
    Binding(
      get: { model.configuration.formatMaxWidth },
      set: { newValue in
        model.configuration.formatMaxWidth = newValue
        model.saveConfig()
      }
    )
  }

  private var minConfidence: Binding<Confidence> {
    Binding(
      get: { model.configuration.suggestMinConfidence },
      set: { newValue in
        model.configuration.suggestMinConfidence = newValue
        model.saveConfig()
      }
    )
  }

  var body: some View {
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
          model.showingConfigPicker = true
        }
      }

      Section("Format") {
        Picker("Indentation", selection: indentation) {
          Text("Spaces").tag("spaces")
          Text("Tabs").tag("tabs")
        }

        if model.configuration.formatIndent != "\t" {
          Stepper(
            "Indent Width: \(model.configuration.formatIndent.count)",
            value: indentWidth,
            in: 1...8
          )
        }

        Stepper(
          "Max Line Width: \(model.configuration.formatMaxWidth)",
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
    .fileImporter(
      isPresented: Bindable(model).showingConfigPicker,
      allowedContentTypes: [.yaml]
    ) { result in
      model.handleConfigFileSelected(result)
    }
    .fileDialogBrowserOptions(.includeHiddenFiles)
  }
}
