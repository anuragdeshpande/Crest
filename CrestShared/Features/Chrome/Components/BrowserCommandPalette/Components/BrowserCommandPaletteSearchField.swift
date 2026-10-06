import SwiftUI

struct BrowserCommandPaletteSearchField: View {
    let model: BrowserCommandPaletteModel
    let presentation: BrowserCommandPalettePresentation
    let queryIsFocused: FocusState<Bool>.Binding

    @ScaledMetric(relativeTo: .title2) private var fieldHeight = 32.0

    var body: some View {
        HStack(spacing: BrowserCommandPaletteMetrics.searchFieldSpacing) {
            Image(systemName: "magnifyingglass")
                .font(.title2.weight(.medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            if let site = model.activeSiteSearch {
                Button {
                    model.leaveSiteSearch()
                } label: {
                    BrowserSiteSearchPill(site: site, showsCloseControl: true, profileID: model.space?.profileID)
                }
                .buttonStyle(.plain)
                .help("Leave site search (Escape)")
                .accessibilityLabel("Stop searching \(site.name)")
                .accessibilityIdentifier("command-palette-site-search-token")
            }

            BrowserPlatformCommandPaletteField(
                model: model,
                presentation: presentation,
                identifier: presentation == .overlay
                    ? "command-palette-field" : "start-page-command-palette-field",
                focused: queryIsFocused.wrappedValue
            )
            .focused(queryIsFocused)
            .frame(height: fieldHeight)

            if let site = model.siteSearchOffer {
                Button {
                    model.acceptSiteSearch()
                } label: {
                    HStack(spacing: CrestSpacing.small) {
                        Text("Search")
                        BrowserSiteSearchPill(site: site, profileID: model.space?.profileID)
                        Label("Tab", systemImage: "arrow.right.to.line")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Press Tab to search this site")
                .accessibilityLabel("Search \(site.name)")
                .accessibilityHint("Press Tab, enter your query, then press Return.")
                .accessibilityIdentifier("command-palette-site-search-offer")
            } else if let completion = model.urlCompletion {
                Button {
                    model.acceptURLCompletion()
                } label: {
                    #if os(macOS)
                        Label("Tab", systemImage: "arrow.right.to.line")
                            .font(.caption)
                    #else
                        Image(systemName: "arrow.right.to.line")
                    #endif
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Accept URL completion (Tab or Right Arrow)")
                .accessibilityLabel("Accept URL completion")
                .accessibilityValue(completion.accepted)
                .accessibilityHint("Fills the address without opening it. Press Tab or Right Arrow to accept.")
                .accessibilityIdentifier("command-palette-accept-completion")
            }

            if presentation == .overlay {
                Button("Close", systemImage: "xmark", action: model.dismiss)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, BrowserCommandPaletteMetrics.searchFieldHorizontalPadding)
        .frame(minHeight: BrowserCommandPaletteMetrics.searchFieldMinimumHeight)
    }
}

#if DEBUG
    #Preview("Search field") {
        @Previewable @FocusState var focused: Bool
        BrowserCommandPaletteSearchField(
            model: BrowserCommandPalettePreviewFixture.model(query: "swift"), presentation: .overlay,
            queryIsFocused: $focused
        )
        .padding().frame(width: 600)
    }
#endif
