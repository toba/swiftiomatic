import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax

enum SidebarSelection: Hashable {
    case options
    case rule(RuleConfigurationEntry)
}

struct ContentView: View {
    @Bindable var document: SwiftiomaticDocument
    @State private var selection: SidebarSelection? = .options
    @State private var searchText = ""
    @State private var scopeFilter: ScopeFilter = .all

    enum ScopeFilter: String, CaseIterable {
        case all = "All"
        case lint = "Lint"
        case format = "Format"
        case suggest = "Suggest"

        var symbolName: String {
            switch self {
            case .all: "list.bullet"
            case .lint: "exclamationmark.triangle"
            case .format: "guidepoint.vertical.numbers"
            case .suggest: "character.textbox.badge.sparkles"
            }
        }
    }

    private var filteredRules: [RuleConfigurationEntry] {
        document.rules.filter { entry in
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
                ForEach(filteredRules) { entry in
                    RuleRow(document: document, entry: entry)
                        .tag(SidebarSelection.rule(entry))
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Filter rules", text: $searchText)
                            .textFieldStyle(.plain)
                        Picker("Scope", selection: $scopeFilter) {
                            ForEach(ScopeFilter.allCases, id: \.self) { filter in
                                Label(filter.rawValue, systemImage: filter.symbolName).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)
                        .fixedSize()
                    }
                    .padding(8)

                    Divider()

                    Button {
                        selection = .options
                    } label: {
                        Label("Format Options", systemImage: "gearshape")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background {
                                if selection == .options {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.tint.opacity(0.15))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)

                    Divider()
                }
                .background(.bar)
            }
            .navigationTitle("Swiftiomatic")
            .navigationSplitViewColumnWidth(min: 280, ideal: 340, max: 500)
        } detail: {
            switch selection {
            case .options:
                FormatOptions(document: document)
            case .rule(let entry):
                RuleDetailView(document: document, entry: entry)
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

