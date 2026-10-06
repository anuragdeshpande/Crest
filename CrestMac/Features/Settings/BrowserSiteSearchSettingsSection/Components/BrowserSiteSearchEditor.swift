import SwiftUI

struct BrowserSiteSearchEditor: View {
    let entry: BrowserSiteSearch
    let isNew: Bool
    var profileID: UUID? = nil
    let save: (BrowserSiteSearch) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: BrowserSiteSearch?
    @State private var aliasesText = ""
    @State private var errorMessage: String?
    @FocusState private var nameIsFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: CrestSpacing.medium) {
            Text(isNew ? "Add Site Search" : "Edit Site Search")
                .font(.title2.weight(.semibold))
            Form {
                TextField("Name", text: draftBinding(\.name))
                    .focused($nameIsFocused)
                    .accessibilityIdentifier("site-search-name")
                TextField("Shortcut", text: draftBinding(\.shortcut))
                    .accessibilityIdentifier("site-search-shortcut")
                TextField("Other shortcuts", text: $aliasesText)
                    .accessibilityIdentifier("site-search-aliases")
                TextField("Search URL", text: draftBinding(\.template))
                    .accessibilityIdentifier("site-search-url")
                ColorPicker("Color", selection: colorBinding, supportsOpacity: false)
                    .accessibilityIdentifier("site-search-color")
            }

            BrowserSiteSearchPill(site: draft ?? entry, showsCloseControl: true, profileID: profileID)
                .accessibilityLabel("Site search pill preview")
            CrestFormFootnote("Other shortcuts are optional. Separate them with commas, such as gpt, openai.")
            CrestFormFootnote(
                "Use an HTTPS URL with exactly one %s or {searchTerms} where the search words go. For example: https://www.google.com/search?q=%s"
            )
            CrestFormFootnote(
                "Sign in on the website instead of putting passwords or tokens in the URL."
            )
            if let errorMessage {
                Text(verbatim: errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("site-search-editor-error")
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { saveDraft() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("save-site-search")
            }
        }
        .padding(24)
        .frame(width: 460)
        .onAppear {
            if draft == nil {
                draft = entry
                aliasesText = entry.aliases.joined(separator: ", ")
            }
            nameIsFocused = true
        }
    }

    private func draftBinding(_ keyPath: WritableKeyPath<BrowserSiteSearch, String>) -> Binding<String> {
        Binding {
            (draft ?? entry)[keyPath: keyPath]
        } set: { value in
            var updated = draft ?? entry
            updated[keyPath: keyPath] = value
            draft = updated
        }
    }

    private var colorBinding: Binding<Color> {
        Binding {
            (draft ?? entry).color.color
        } set: { value in
            var updated = draft ?? entry
            updated.color = BrandColor(color: value)
            draft = updated
        }
    }

    private func saveDraft() {
        do {
            var updated = draft ?? entry
            updated.aliases = aliasesText.split(separator: ",").map(String.init)
            try save(updated)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

}

#if DEBUG
    #Preview("Edit site search") {
        BrowserSiteSearchEditor(entry: BrowserSiteSearch.builtIn[0], isNew: false, save: { _ in })
    }
#endif
