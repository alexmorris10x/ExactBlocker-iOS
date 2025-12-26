import SwiftUI
import UniformTypeIdentifiers

struct BlockListView: View {
    @EnvironmentObject var store: BlockStore
    @State private var newHost = ""
    @State private var newElementRule = ""
    @State private var showingImporter = false
    @State private var importAlert: ImportAlert?
    @State private var reloadAlert = false

    struct ImportAlert: Identifiable {
        let id = UUID()
        let message: String
    }

    var body: some View {
        NavigationStack {
            List {
                // ─────────────────────────────────────────────────────────
                // SECTION 1: Website Blocking (existing functionality)
                // ─────────────────────────────────────────────────────────
                Section {
                    ForEach(store.hosts, id: \.self) { host in
                        Text(host)
                            .swipeActions {
                                Button(role: .destructive) {
                                    store.hosts.removeAll { $0 == host }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text("Blocked Websites")
                } footer: {
                    Text("Blocks the entire page from loading")
                }

                // Add host input
                Section("Add Website") {
                    HStack {
                        TextField("reddit.com", text: $newHost)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Add") {
                            store.add(host: newHost)
                            newHost = ""
                        }
                        .disabled(newHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                // ─────────────────────────────────────────────────────────
                // SECTION 2: Element Hiding (new functionality)
                // ─────────────────────────────────────────────────────────
                Section {
                    ForEach(store.elementRules) { rule in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.domain)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(rule.selector)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(1)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                store.elementRules.removeAll { $0 == rule }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Hidden Elements")
                } footer: {
                    Text("Hides specific elements on pages (like uBlock)")
                }

                // Add element rule input
                Section("Add Element Rule") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("domain.com##.selector", text: $newElementRule)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(.body, design: .monospaced))

                        HStack {
                            Button("Add Rule") {
                                if let rule = ElementRule.parse(newElementRule) {
                                    store.add(elementRule: rule)
                                    newElementRule = ""
                                }
                            }
                            .disabled(ElementRule.parse(newElementRule) == nil)

                            Spacer()

                            Button {
                                showingImporter = true
                            } label: {
                                Label("Import File", systemImage: "doc.badge.plus")
                            }
                        }
                    }
                }

                // ─────────────────────────────────────────────────────────
                // SECTION 3: Actions
                // ─────────────────────────────────────────────────────────
                Section {
                    Button {
                        store.writeRulesAndReload()
                        reloadAlert = true
                    } label: {
                        Label("Reload Safari Rules", systemImage: "arrow.clockwise")
                    }

                    Button {
                        store.elementRules.removeAll()
                    } label: {
                        Label("Clear All Element Rules", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                    .disabled(store.elementRules.isEmpty)
                } footer: {
                    Text("\(store.hosts.count) website rules, \(store.elementRules.count) element rules")
                }
            }
            .navigationTitle("Exact Blocker")
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert(item: $importAlert) { alert in
                Alert(title: Text("Import Complete"), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
            .alert("Rules Reloaded", isPresented: $reloadAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Safari content blocker has been refreshed with \(store.hosts.count + store.elementRules.count) rules.")
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Need to start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                importAlert = ImportAlert(message: "Could not access file")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                let count = store.importElementRules(from: text)
                importAlert = ImportAlert(message: "Imported \(count) new rules")
            } catch {
                importAlert = ImportAlert(message: "Error reading file: \(error.localizedDescription)")
            }

        case .failure(let error):
            importAlert = ImportAlert(message: "Import failed: \(error.localizedDescription)")
        }
    }
}
