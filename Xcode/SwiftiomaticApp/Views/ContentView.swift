import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax

enum SidebarSelection: Hashable {
    case options
    case rule(RuleConfigurationEntry)
}

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @State private var selection: SidebarSelection? = .options
    @State private var searchText = ""
    @State private var scopeFilter: ScopeFilter = .all

    enum ScopeFilter: String, CaseIterable {
        case all = "All"
        case lint = "Lint"
        case format = "Format"
        case suggest = "Suggest"
    }

    private var filteredRules: [RuleConfigurationEntry] {
        model.rules.filter { entry in
            switch scopeFilter {
            case .all: true
            case .lint: entry.scope == .lint
            case .format: entry.scope == .format
            case .suggest: entry.scope == .suggest
            }
        }.filter {
            searchText.isEmpty
                || $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.id.localizedCaseInsensitiveContains(searchText)
                || $0.summary.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    Label("Format Options", systemImage: "gearshape")
                        .tag(SidebarSelection.options)
                }

                Section("Rules") {
                    ForEach(filteredRules) { entry in
                        RuleRow(entry: entry)
                            .tag(SidebarSelection.rule(entry))
                    }
                }
            }
            .searchable(text: $searchText, placement: .sidebar, prompt: "Filter rules")
            .toolbar {
                ToolbarItem {
                    Picker("Scope", selection: $scopeFilter) {
                        ForEach(ScopeFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Swiftiomatic")
            .navigationSplitViewColumnWidth(min: 280, ideal: 340, max: 500)
        } detail: {
            switch selection {
            case .options:
                FormatOptions()
            case .rule(let entry):
                RuleDetailView(entry: entry)
            case nil:
                ContentUnavailableView(
                    "Select an Item",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Choose a rule or Format Options from the sidebar.")
                )
            }
        }
    }
}

