import Foundation
import OSLog
import Observation

/// Device-local search shortcuts do not change a Space's default search engine.
@MainActor @Observable
final class BrowserSiteSearchStore {
    static let shared = BrowserSiteSearchStore(defaults: BrowserFolderAppearancePreference.defaults)
    static let storageKey = "crest.site-searches.v1"
    static let catalogVersionKey = "crest.site-searches.catalog-version"
    private static let catalogVersion = 2
    private static let logger = Logger(subsystem: "com.pauldavis.crest", category: "SiteSearch")

    private(set) var entries: [BrowserSiteSearch] = []
    private(set) var errorMessage: String?
    @ObservationIgnored private let defaults: UserDefaults?

    init(defaults: UserDefaults? = nil, entries: [BrowserSiteSearch] = BrowserSiteSearch.builtIn) {
        self.defaults = defaults
        guard let stored = defaults?.object(forKey: Self.storageKey) else {
            self.entries = entries
            defaults?.set(Self.catalogVersion, forKey: Self.catalogVersionKey)
            return
        }
        do {
            guard let data = stored as? Data else { throw BrowserSiteSearchError.unreadableStorage }
            let saved = try JSONDecoder().decode([BrowserSiteSearch].self, from: data)
            let validated = try saved.map { try $0.validated() }
            guard Set(validated.map(\.id)).count == validated.count,
                Set(validated.flatMap(\.shortcuts)).count == validated.flatMap(\.shortcuts).count
            else { throw BrowserSiteSearchError.unreadableStorage }
            self.entries = validated
            if let defaults, defaults.integer(forKey: Self.catalogVersionKey) < Self.catalogVersion {
                let upgraded = Self.upgradedCatalog(validated)
                if upgraded != validated { try persist(upgraded) }
                defaults.set(Self.catalogVersion, forKey: Self.catalogVersionKey)
            }
        } catch {
            errorMessage = BrowserSiteSearchError.unreadableStorage.localizedDescription
            Self.logger.error("Unable to decode saved site searches; original settings preserved.")
        }
    }

    func match(_ query: String) -> BrowserSiteSearch? {
        guard errorMessage == nil else { return nil }
        let word = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !word.isEmpty, !word.contains(where: { $0.isWhitespace }), !word.contains("/") else { return nil }
        if let exact = entries.first(where: { $0.shortcuts.contains(word) || $0.name.lowercased() == word }) {
            return exact
        }
        guard word.count >= 2 else { return nil }
        return entries.filter {
            let host = $0.host.hasPrefix("www.") ? String($0.host.dropFirst(4)) : $0.host
            return $0.name.lowercased().replacingOccurrences(of: " ", with: "").hasPrefix(word)
                || $0.shortcuts.contains(where: { $0.hasPrefix(word) })
                || host.hasPrefix(word)
        }.sorted {
            $0.name.count == $1.name.count ? $0.name < $1.name : $0.name.count < $1.name.count
        }.first
    }

    func save(_ entry: BrowserSiteSearch) throws {
        let entry = try entry.validated()
        guard
            !entries.contains(where: {
                $0.id != entry.id && !Set($0.shortcuts).isDisjoint(with: entry.shortcuts)
            })
        else {
            throw BrowserSiteSearchError.duplicateShortcut
        }
        var updated = entries
        if let index = updated.firstIndex(where: { $0.id == entry.id }) {
            updated[index] = entry
        } else {
            updated.append(entry)
        }
        try persist(updated)
    }

    func remove(_ id: UUID) throws {
        try persist(entries.filter { $0.id != id })
    }

    private static func upgradedCatalog(_ saved: [BrowserSiteSearch]) -> [BrowserSiteSearch] {
        guard !saved.isEmpty else { return saved }
        var updated = saved
        for site in BrowserSiteSearch.builtIn {
            let used = Set(updated.flatMap(\.shortcuts))
            if let index = updated.firstIndex(where: { $0.id == site.id }) {
                if updated[index].shortcut == site.shortcut {
                    updated[index].aliases += site.aliases.filter { !used.contains($0) }
                }
            } else if !BrowserSiteSearch.builtIn.prefix(5).contains(where: { $0.id == site.id }) {
                // Add only the new catalog, never resurrect a removed original site.
                guard !used.contains(site.shortcut),
                    !updated.contains(where: { $0.host == site.host })
                else {
                    logger.notice("Preserved an existing site search instead of adding a conflicting default.")
                    continue
                }
                var addition = site
                addition.aliases = site.aliases.filter { !used.contains($0) }
                updated.append(addition)
            }
        }
        return updated
    }

    private func persist(_ updated: [BrowserSiteSearch]) throws {
        guard errorMessage == nil else { throw BrowserSiteSearchError.unreadableStorage }
        let data = try JSONEncoder().encode(updated)
        defaults?.set(data, forKey: Self.storageKey)
        entries = updated
    }
}
