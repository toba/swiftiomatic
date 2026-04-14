import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax

enum SidebarSelection: Hashable {
    case options
    case category(DisplayCategory)
}

struct ContentView: View {
    @Bindable var store: ConfigStore
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
        store.rules.filter { entry in
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

    private var rulesByCategory: [DisplayCategory: [RuleConfigurationEntry]] {
        Dictionary(grouping: filteredRules) { DisplayCategory.from($0.category) }
    }

    var body: some View {
        NavigationSplitView {
            let grouped = rulesByCategory
            List(selection: $selection) {
                ForEach(CategoryGroup.allCases) { group in
                    let groupCategories = DisplayCategory.categories(in: group)
                        .filter { grouped[$0] != nil }
                    if !groupCategories.isEmpty {
                        Section(group.rawValue) {
                            ForEach(groupCategories) { category in
                                let count = grouped[category]?.count ?? 0
                                Label {
                                    HStack {
                                        Text(category.displayName)
                                        Spacer()
                                        Text("\(count)")
                                            .foregroundStyle(.secondary)
                                            .font(.callout)
                                    }
                                } icon: {
                                    Image(systemName: category.symbolName)
                                }
                                .tag(SidebarSelection.category(category))
                            }
                        }
                    }
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
                FormatOptions(store: store)
            case .category(let category):
                CategoryDetailView(
                    store: store,
                    category: category,
                    rules: rulesByCategory[category] ?? []
                )
            case nil:
                ContentUnavailableView(
                    "Select a Category",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Choose a rule category or Format Options from the sidebar.")
                )
            }
        }
    }
}
