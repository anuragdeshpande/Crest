import SwiftUI

struct BrowserSiteSearchPill: View {
    let site: BrowserSiteSearch
    var showsCloseControl = false
    var profileID: UUID? = nil

    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.browserSpaceContentIsLocked) private var isLocked

    private var iconProvider: SearchProvider {
        if let provider = SearchProvider.all.first(where: {
            URL(string: $0.searchTemplate.replacingOccurrences(of: "%s", with: ""))?.host == site.host
        }) {
            return provider
        }
        return SearchProvider(
            name: SearchProvider.customPrefix + site.id.coreIdentifier,
            title: site.name, logo: nil, searchTemplate: site.template, suggestionTemplate: nil)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: CrestRadius.compact, style: .continuous)
        HStack(spacing: CrestSpacing.small) {
            BrowserSearchProviderIcon(
                provider: iconProvider, profileID: isLocked ? nil : profileID, size: 14
            )
            .id(site.host)
            Text(verbatim: site.name.isEmpty ? String(localized: "Site") : site.name)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
            if showsCloseControl {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(Color.primary)
            }
        }
        .padding(.horizontal, CrestSpacing.small)
        .padding(.vertical, 4)
        .background(site.color.color.opacity(contrast == .increased ? 0.08 : 0.16), in: shape)
        .background(.background, in: shape)
        .overlay {
            shape.strokeBorder(
                contrast == .increased ? Color.primary : site.color.color.mix(with: .primary, by: 0.35),
                lineWidth: contrast == .increased ? 1.5 : 1
            )
            .allowsHitTesting(false)
        }
    }
}
