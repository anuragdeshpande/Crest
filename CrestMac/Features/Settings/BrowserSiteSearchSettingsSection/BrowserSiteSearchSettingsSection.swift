import SwiftUI

struct BrowserSiteSearchSettingsSection: View {
    let store: BrowserSiteSearchStore
    var profileID: UUID? = nil

    @State private var editorEntry: BrowserSiteSearch?
    @State private var pendingRemoval: BrowserSiteSearch?
    @State private var errorMessage: String?

    var body: some View {
        Section("Site Searches", systemImage: "magnifyingglass") {
            CrestFormFootnote(
                "Type a site name or shortcut, press Tab, then enter your query. Press Return to open the results."
            )
            if let message = store.errorMessage {
                Text(verbatim: message)
                    .foregroundStyle(.red)
            } else {
                ForEach(store.entries) { entry in
                    HStack(spacing: CrestSpacing.small) {
                        Button {
                            editorEntry = entry
                        } label: {
                            HStack(spacing: CrestSpacing.small) {
                                Circle()
                                    .fill(entry.color.color)
                                    .frame(width: 10, height: 10)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(verbatim: entry.name)
                                    Text(verbatim: "\(entry.shortcuts.joined(separator: ", ")) · \(entry.host)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .help("Edit site search")
                        .accessibilityLabel("Edit \(entry.name)")
                        .accessibilityIdentifier("site-search-edit-\(entry.id.uuidString)")

                        Button("Remove", systemImage: "minus.circle", role: .destructive) {
                            pendingRemoval = entry
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .help("Remove site search")
                        .accessibilityLabel("Remove \(entry.name)")
                        .accessibilityIdentifier("site-search-remove-\(entry.id.uuidString)")
                    }
                    .contextMenu {
                        Button("Edit…") { editorEntry = entry }
                        Button("Remove", role: .destructive) { pendingRemoval = entry }
                    }
                }
                if store.entries.isEmpty {
                    Text("No site searches. Add a site to get started.")
                        .foregroundStyle(.secondary)
                }
                Button("Add Site Search…", systemImage: "plus") {
                    editorEntry = .new()
                }
                .accessibilityIdentifier("add-site-search")
            }
            CrestFormFootnote(
                "Available in every Space on this Mac. Site searches stay on this device and don’t change your default search engine."
            )
        }
        .sheet(item: $editorEntry) { entry in
            BrowserSiteSearchEditor(
                entry: entry, isNew: !store.entries.contains(where: { $0.id == entry.id }), profileID: profileID
            ) {
                try store.save($0)
            }
        }
        .confirmationDialog(
            "Remove Site Search?",
            isPresented: Binding(
                get: { pendingRemoval != nil },
                set: { if !$0 { pendingRemoval = nil } }),
            presenting: pendingRemoval
        ) { entry in
            Button("Remove \(entry.name)", role: .destructive) {
                do {
                    try store.remove(entry.id)
                } catch {
                    errorMessage = error.localizedDescription
                }
                pendingRemoval = nil
            }
            Button("Cancel", role: .cancel) { pendingRemoval = nil }
        }
        .alert(
            "Couldn’t Remove Site Search",
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(verbatim: errorMessage ?? "")
        }
    }
}

#if DEBUG
    #Preview("Site searches") {
        Form {
            BrowserSiteSearchSettingsSection(store: BrowserSiteSearchStore())
        }
        .padding().frame(width: 520)
    }
#endif
