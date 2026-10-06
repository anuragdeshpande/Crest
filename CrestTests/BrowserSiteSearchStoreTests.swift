import Foundation
import XCTest

@testable import Crest

@MainActor
final class BrowserSiteSearchStoreTests: XCTestCase {
    func testSavingEditingRemovingAndReloadingPreservesAnEmptyList() throws {
        let suite = "crest.test.site-search.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = BrowserSiteSearchStore(defaults: defaults, entries: [])
        var entry = BrowserSiteSearch(
            id: UUID(), name: " Example ", shortcut: " EX ", template: "https://example.com/?q={searchTerms}")
        try store.save(entry)
        XCTAssertEqual(store.entries.first?.name, "Example")
        XCTAssertEqual(store.entries.first?.shortcut, "ex")
        XCTAssertEqual(store.entries.first?.template, "https://example.com/?q=%s")
        entry.name = "Edited"
        try store.save(entry)
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(BrowserSiteSearchStore(defaults: defaults).entries.first?.name, "Edited")
        try store.remove(entry.id)
        XCTAssertTrue(BrowserSiteSearchStore(defaults: defaults).entries.isEmpty)
    }

    func testMatchesNamesShortcutsAndHostsWithoutMatchingQueriesOrURLs() {
        let store = BrowserSiteSearchStore()
        XCTAssertEqual(store.match(" GOOGLE ")?.name, "Google")
        XCTAssertEqual(store.match("goo")?.name, "Google")
        XCTAssertEqual(store.match("yt")?.name, "YouTube")
        XCTAssertEqual(store.match("github.com")?.name, "GitHub")
        for query in ["z", "google cats", "https://google.com", "google.com/search", ""] {
            XCTAssertNil(store.match(query), query)
        }
    }

    func testCompleteCatalogHasValidUniqueEntriesAndSearchAliases() throws {
        let sites = try BrowserSiteSearch.builtIn.map { try $0.validated() }
        XCTAssertEqual(
            Set(sites.map(\.name)),
            Set([
                "Google", "YouTube", "Wikipedia", "GitHub", "Reddit", "X", "ChatGPT", "Claude",
                "Perplexity", "Stack Overflow", "MDN", "Amazon", "IMDb", "Spotify", "Figma Community",
            ]))
        XCTAssertEqual(Set(sites.map(\.id)).count, 15)
        XCTAssertEqual(Set(sites.flatMap(\.shortcuts)).count, sites.flatMap(\.shortcuts).count)
        let store = BrowserSiteSearchStore()
        for (query, name) in [
            ("g", "Google"), ("yt", "YouTube"), ("wiki", "Wikipedia"), ("gh", "GitHub"),
            ("twitter", "X"), ("gpt", "ChatGPT"), ("openai", "ChatGPT"), ("so", "Stack Overflow"),
            ("mdn", "MDN"), ("figma", "Figma Community"), ("cla", "Claude"), ("perp", "Perplexity"),
        ] {
            XCTAssertEqual(store.match(query)?.name, name)
        }
        XCTAssertEqual(
            store.match("spotify")?.url(for: "a/b + c")?.absoluteString,
            "https://open.spotify.com/search/a%2Fb%20%2B%20c")
        XCTAssertEqual(
            store.match("claude")?.url(for: "native apps")?.absoluteString,
            "https://claude.ai/new?q=native%20apps")
        XCTAssertEqual(
            store.match("figma")?.url(for: "native apps")?.absoluteString,
            "https://www.figma.com/community/search?resource_type=mixed&sort_by=relevancy&query=native%20apps")
        XCTAssertEqual(Set(sites.map(\.color)).count, 15)
        XCTAssertEqual(sites[0].color, BrandColor(red: 66.0 / 255, green: 133.0 / 255, blue: 244.0 / 255))
    }

    func testAliasesAndCustomColorAreValidatedAndPersisted() throws {
        let suite = "crest.test.site-search.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = BrowserSiteSearchStore(defaults: defaults, entries: [])
        var site = BrowserSiteSearch(
            id: UUID(), name: "Example", shortcut: "ex", template: "https://example.com/?q=%s",
            aliases: [" ALT ", "other"], color: .rose)
        try store.save(site)
        let reloaded = BrowserSiteSearchStore(defaults: defaults)
        XCTAssertEqual(reloaded.entries.first?.aliases, ["alt", "other"])
        XCTAssertEqual(reloaded.entries.first?.color, .rose)
        XCTAssertEqual(reloaded.match("alt")?.id, site.id)
        XCTAssertEqual(reloaded.match("oth")?.id, site.id)
        for aliases in [["ex"], ["alt", "ALT"], ["two words"], ["bad/alias"], ["bad:alias"], [""]] {
            site.aliases = aliases
            XCTAssertThrowsError(try store.save(site))
        }
        var duplicate = BrowserSiteSearch.builtIn[0]
        duplicate.aliases = ["ALT"]
        XCTAssertThrowsError(try store.save(duplicate))
        duplicate.aliases = []
        duplicate.shortcut = "other"
        XCTAssertThrowsError(try store.save(duplicate))
    }

    func testLegacyCatalogUpgradePreservesEditsAndRemovalsAndRunsOnlyOnce() throws {
        let suite = "crest.test.site-search.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var saved = Array(BrowserSiteSearch.builtIn.prefix(5))
        saved.removeAll { $0.name == "Reddit" }
        saved[0].name = "My Google"
        saved[0].template = "https://www.google.com/search?q=%s&safe=active"
        let objects = saved.map { entry -> [String: String] in
            ["id": entry.id.uuidString, "name": entry.name, "shortcut": entry.shortcut, "template": entry.template]
        }
        defaults.set(try JSONSerialization.data(withJSONObject: objects), forKey: BrowserSiteSearchStore.storageKey)
        let store = BrowserSiteSearchStore(defaults: defaults)
        XCTAssertNil(store.errorMessage)
        XCTAssertEqual(store.entries.count, 14)
        XCTAssertNil(store.match("reddit"))
        XCTAssertEqual(store.entries[0].name, "My Google")
        XCTAssertEqual(store.entries[0].template, saved[0].template)
        XCTAssertEqual(store.entries[0].color, BrowserSiteSearch.builtIn[0].color)
        XCTAssertEqual(store.match("g")?.id, saved[0].id)
        let claude = try XCTUnwrap(store.match("claude"))
        try store.remove(claude.id)
        let reloaded = BrowserSiteSearchStore(defaults: defaults)
        XCTAssertEqual(reloaded.entries.count, 13)
        XCTAssertNil(reloaded.match("claude"))
    }

    func testLegacyUpgradeDoesNotResurrectAnEmptyListOrClaimCustomShortcuts() throws {
        let suite = "crest.test.site-search.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("[]".utf8), forKey: BrowserSiteSearchStore.storageKey)
        XCTAssertTrue(BrowserSiteSearchStore(defaults: defaults).entries.isEmpty)
        defaults.removeObject(forKey: BrowserSiteSearchStore.catalogVersionKey)
        let custom = BrowserSiteSearch(
            id: UUID(), name: "Work", shortcut: "gpt", template: "https://example.com/?q=%s", color: .gold)
        defaults.set(try JSONEncoder().encode([custom]), forKey: BrowserSiteSearchStore.storageKey)
        let store = BrowserSiteSearchStore(defaults: defaults)
        XCTAssertNil(store.errorMessage)
        XCTAssertEqual(store.match("gpt")?.id, custom.id)
        XCTAssertEqual(store.match("chatgpt")?.aliases, ["openai"])
        XCTAssertEqual(store.entries.first?.color, .gold)
        XCTAssertNil(store.match("google"))
    }

    func testValidationRejectsUnsafeOrAmbiguousTemplatesAndDuplicateShortcuts() throws {
        let store = BrowserSiteSearchStore(entries: [])
        let valid = BrowserSiteSearch(
            id: UUID(), name: "Example", shortcut: "ex", template: "https://example.com/?q=%s")
        try store.save(valid)
        var duplicate = valid
        duplicate.id = UUID()
        duplicate.shortcut = "EX"
        XCTAssertThrowsError(try store.save(duplicate))
        for template in [
            "http://example.com/?q=%s", "javascript:alert('%s')", "https://example.com/",
            "https://example.com/?q=%s&other=%s", "https://%s.example.com/",
            "https://user:password@example.com/?q=%s", "https://example.com/#%s",
        ] {
            var invalid = valid
            invalid.template = template
            XCTAssertThrowsError(try store.save(invalid))
        }
        var invalid = valid
        invalid.name = " "
        XCTAssertThrowsError(try store.save(invalid))
        invalid = valid
        invalid.shortcut = "two words"
        XCTAssertThrowsError(try store.save(invalid))
        XCTAssertEqual(store.entries, [valid])
    }

    func testQueryEncodingPreventsParameterInjectionAndWorksInPaths() throws {
        let site = BrowserSiteSearch.builtIn[0]
        XCTAssertEqual(
            site.url(for: "cats & dogs/#? café")?.absoluteString,
            "https://www.google.com/search?q=cats%20%26%20dogs%2F%23%3F%20caf%C3%A9")
        let path = BrowserSiteSearch(
            id: UUID(), name: "Example", shortcut: "ex", template: "https://example.com/search/%s")
        XCTAssertEqual(path.url(for: "a/b + c")?.absoluteString, "https://example.com/search/a%2Fb%20%2B%20c")
        XCTAssertNil(site.url(for: " \n "))
    }

    func testCorruptStorageIsReportedAndNeverOverwritten() throws {
        let suite = "crest.test.site-search.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = Data("not valid JSON".utf8)
        defaults.set(original, forKey: BrowserSiteSearchStore.storageKey)
        let store = BrowserSiteSearchStore(defaults: defaults)
        XCTAssertNotNil(store.errorMessage)
        XCTAssertTrue(store.entries.isEmpty)
        XCTAssertNil(store.match("google"))
        XCTAssertThrowsError(try store.save(BrowserSiteSearch.builtIn[0]))
        XCTAssertEqual(defaults.data(forKey: BrowserSiteSearchStore.storageKey), original)
        defaults.set("unexpected type", forKey: BrowserSiteSearchStore.storageKey)
        XCTAssertNotNil(BrowserSiteSearchStore(defaults: defaults).errorMessage)
    }
}
