import AppKit
import XCTest

@testable import Crest

@MainActor
final class BrowserSiteSearchPaletteTests: XCTestCase {
    func testTabSelectsSiteClearsNativeFieldAndReturnNavigatesWithoutWaiting() async throws {
        var destination: URL?
        let fixture = makeEditor(openURL: { destination = $0 })
        defer { fixture.window.close() }
        let editor = try XCTUnwrap(fixture.field.currentEditor() as? NSTextView)
        editor.insertText("google", replacementRange: NSRange(location: 0, length: 0))
        fixture.coordinator.editingChanged()
        XCTAssertEqual(fixture.model.siteSearchOffer?.name, "Google")
        XCTAssertTrue(
            fixture.coordinator.control(
                fixture.field, textView: editor, doCommandBy: #selector(NSResponder.insertTab(_:))))
        XCTAssertEqual(fixture.model.activeSiteSearch?.name, "Google")
        XCTAssertEqual(editor.string, "")
        XCTAssertEqual(fixture.model.query, "")
        XCTAssertTrue(fixture.model.items.isEmpty)
        fixture.model.activateSelectedResult()
        XCTAssertNil(destination)
        editor.insertText("https://example.com/?a=1&b=2", replacementRange: NSRange(location: 0, length: 0))
        fixture.coordinator.editingChanged()
        XCTAssertNil(fixture.model.urlCompletion)
        XCTAssertEqual(fixture.model.items.count, 1)
        XCTAssertTrue(
            fixture.coordinator.control(
                fixture.field, textView: editor, doCommandBy: #selector(NSResponder.insertNewline(_:))))
        XCTAssertEqual(
            destination?.absoluteString, "https://www.google.com/search?q=https%3A%2F%2Fexample.com%2F%3Fa%3D1%26b%3D2")
        await fixture.model.waitForPendingResults()
        XCTAssertEqual(fixture.model.items.count, 1, "A stale default-provider answer must not replace the site query.")
    }

    func testSelectionCompositionAndStaleSourceDoNotConsumeTab() async throws {
        var available = true
        let fixture = makeEditor(isAvailable: { available })
        defer { fixture.window.close() }
        let editor = try XCTUnwrap(fixture.field.currentEditor() as? NSTextView)
        editor.insertText("google", replacementRange: NSRange(location: 0, length: 0))
        editor.setSelectedRange(NSRange(location: 2, length: 0))
        fixture.coordinator.editingChanged()
        XCTAssertNil(fixture.model.siteSearchOffer)
        XCTAssertFalse(fixture.model.acceptSiteSearch())
        editor.setSelectedRange(NSRange(location: 6, length: 0))
        fixture.coordinator.editingChanged()
        available = false
        XCTAssertNil(fixture.model.siteSearchOffer)
        XCTAssertFalse(fixture.model.acceptSiteSearch())
        available = true
        editor.setMarkedText(
            "g", selectedRange: NSRange(location: 1, length: 0), replacementRange: NSRange(location: 0, length: 6))
        fixture.coordinator.editingChanged()
        XCTAssertNil(fixture.model.siteSearchOffer)
        XCTAssertFalse(
            fixture.coordinator.control(
                fixture.field, textView: editor, doCommandBy: #selector(NSResponder.insertTab(_:))))
    }

    func testEscapeAndEmptyBackspaceLeaveSiteModeAndPreserveTyping() async throws {
        let fixture = makeEditor()
        defer { fixture.window.close() }
        let editor = try XCTUnwrap(fixture.field.currentEditor() as? NSTextView)
        editor.insertText("google", replacementRange: NSRange(location: 0, length: 0))
        fixture.coordinator.editingChanged()
        XCTAssertTrue(fixture.model.acceptSiteSearch())
        XCTAssertFalse(
            fixture.coordinator.control(
                fixture.field, textView: editor, doCommandBy: #selector(NSResponder.insertBacktab(_:))))
        XCTAssertTrue(
            fixture.coordinator.control(
                fixture.field, textView: editor, doCommandBy: #selector(NSResponder.deleteBackward(_:))))
        XCTAssertNil(fixture.model.activeSiteSearch)
        editor.insertText("yt", replacementRange: NSRange(location: 0, length: 0))
        fixture.coordinator.editingChanged()
        XCTAssertTrue(fixture.model.acceptSiteSearch())
        editor.insertText("cats", replacementRange: NSRange(location: 0, length: 0))
        fixture.coordinator.editingChanged()
        XCTAssertFalse(
            fixture.coordinator.control(
                fixture.field, textView: editor, doCommandBy: #selector(NSResponder.deleteBackward(_:))))
        XCTAssertTrue(
            fixture.coordinator.control(
                fixture.field, textView: editor, doCommandBy: #selector(NSResponder.cancelOperation(_:))))
        XCTAssertNil(fixture.model.activeSiteSearch)
        XCTAssertEqual(fixture.model.query, "cats")
        XCTAssertEqual(editor.string, "cats")
    }

    func testDeletingActiveEntryCannotOpenItsStaleResult() throws {
        let store = BrowserSiteSearchStore()
        var destination: URL?
        let fixture = makeEditor(store: store, openURL: { destination = $0 })
        defer { fixture.window.close() }
        fixture.model.updateCompletionEditing(
            text: "google", selection: NSRange(location: 6, length: 0), isComposing: false)
        XCTAssertTrue(fixture.model.acceptSiteSearch())
        fixture.model.query = "cats"
        let row = try XCTUnwrap(fixture.model.items.first?.row)
        try store.remove(BrowserSiteSearch.builtIn[0].id)
        fixture.model.activate(row)
        XCTAssertNil(destination)
        XCTAssertNil(fixture.model.activeSiteSearch)
    }

    func testEmptyStartPageSelectionCreatesPrivateTabOnlyOnReturn() {
        let space = SpaceState.Seed(name: "Test", symbol: "globe", accent: .indigo, folders: [], tabs: [])
        let browser = BrowserStore(
            seed: SessionState.Seed(spaces: [space]), showing: space.id, browsingMode: .privateBrowsing)
        let access = BrowserSpaceAccessController()
        var selectedCount = 0
        let actions = BrowserEmptySelectionPaletteActions(
            source: BrowserSpaceRuntimeAssignment(space: space), browser: browser,
            accessController: access, didSelectTab: { selectedCount += 1 })
        let model = BrowserCommandPaletteModel(
            browser: browser, space: browser.spaceModel(space.id), selectedTabID: nil, initialQuery: "",
            commands: nil, offersRestingCommands: false,
            isSourceAvailable: { _ in false }, selectTab: { _, _ in false }, openURL: { _, _ in false }, dismiss: {},
            emptySelectionActions: actions, siteSearches: BrowserSiteSearchStore())
        model.updateCompletionEditing(text: "yt", selection: NSRange(location: 2, length: 0), isComposing: false)
        XCTAssertTrue(model.acceptSiteSearch())
        model.query = "cats"
        XCTAssertNil(browser.shownTab)
        XCTAssertEqual(selectedCount, 0)
        model.activateSelectedResult()
        XCTAssertEqual(browser.shownTab?.address?.absoluteString, "https://www.youtube.com/results?search_query=cats")
        XCTAssertEqual(selectedCount, 1)
        XCTAssertEqual(browser.browsingMode, .privateBrowsing)
    }

    func testEditingActiveEntryRefreshesDestinationAndUnavailableSourceCannotNavigate() throws {
        let store = BrowserSiteSearchStore()
        var available = true
        var destination: URL?
        let fixture = makeEditor(store: store, isAvailable: { available }, openURL: { destination = $0 })
        defer { fixture.window.close() }
        fixture.model.updateCompletionEditing(
            text: "google", selection: NSRange(location: 6, length: 0), isComposing: false)
        XCTAssertTrue(fixture.model.acceptSiteSearch())
        fixture.model.query = "cats"
        var site = try XCTUnwrap(fixture.model.activeSiteSearch)
        site.template = "https://example.com/find/%s"
        try store.save(site)
        fixture.model.refreshSiteSearch()
        XCTAssertEqual(fixture.model.items.first?.row.address, "https://example.com/find/cats")
        available = false
        fixture.model.activateSelectedResult()
        XCTAssertNil(destination)
        available = true
        fixture.model.activateSelectedResult()
        XCTAssertEqual(destination?.absoluteString, "https://example.com/find/cats")
    }

    func testSiteQueriesNeverFetchDefaultProviderSuggestions() async {
        let recorder = SiteSearchSuggestionRecorder()
        let fixture = makeEditor(fetchSuggestions: { url in
            await recorder.record(url)
            return []
        })
        defer { fixture.window.close() }
        fixture.model.updateCompletionEditing(
            text: "google", selection: NSRange(location: 6, length: 0), isComposing: false)
        XCTAssertTrue(fixture.model.acceptSiteSearch())
        fixture.model.query = "private search words"
        await fixture.model.waitForPendingResults()
        let count = await recorder.count
        XCTAssertEqual(count, 0)
        XCTAssertEqual(
            fixture.model.items.first?.row.address, "https://www.google.com/search?q=private%20search%20words")
    }

    func testClickingOfferRestoresFieldFocusAfterEditingEnds() throws {
        let fixture = makeEditor()
        defer { fixture.window.close() }
        let editor = try XCTUnwrap(fixture.field.currentEditor() as? NSTextView)
        editor.insertText("google", replacementRange: NSRange(location: 0, length: 0))
        fixture.coordinator.editingChanged()
        fixture.window.makeFirstResponder(nil)
        XCTAssertNil(fixture.field.currentEditor())
        XCTAssertTrue(fixture.model.acceptSiteSearch())
        let focusedEditor = try XCTUnwrap(fixture.field.currentEditor() as? NSTextView)
        XCTAssertTrue(fixture.window.firstResponder === focusedEditor)
        XCTAssertEqual(focusedEditor.string, "")
        XCTAssertEqual(focusedEditor.selectedRange(), NSRange(location: 0, length: 0))
    }

    private func makeEditor(
        store: BrowserSiteSearchStore = BrowserSiteSearchStore(),
        isAvailable: @escaping () -> Bool = { true },
        openURL: @escaping (URL) -> Void = { _ in },
        fetchSuggestions: @escaping @Sendable (URL) async throws -> [String] = { _ in [] }
    ) -> (
        window: NSWindow, field: NSTextField, coordinator: BrowserPlatformCommandPaletteField.Coordinator,
        model: BrowserCommandPaletteModel
    ) {
        let tab = TabState.Seed(title: "Example", url: URL(string: "https://example.com/path"), placement: .current)
        var preferences = BrowsingPreferences.seeded
        preferences.searchProvider = .duckDuckGo
        preferences.searchSuggestionsEnabled = true
        let space = SpaceState.Seed(
            name: "Test", symbol: "globe", accent: .indigo, folders: [], tabs: [tab],
            browsingPreferences: preferences)
        let browser = BrowserStore(
            seed: SessionState.Seed(spaces: [space]), showing: space.id, tabs: [space.id: tab.id])
        let model = BrowserCommandPaletteModel(
            browser: browser, space: browser.spaceModel(space.id), selectedTabID: tab.id, initialQuery: "",
            commands: nil,
            fetchSuggestions: fetchSuggestions,
            isSourceAvailable: { _ in isAvailable() }, selectTab: { _, _ in false },
            openURL: { _, url in
                openURL(url)
                return true
            }, dismiss: {}, siteSearches: store)
        let view = BrowserPlatformCommandPaletteField(
            model: model, presentation: .overlay, identifier: "test-field", focused: false)
        let coordinator = view.makeCoordinator()
        let field = view.makeField(coordinator: coordinator)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 80), styleMask: .borderless, backing: .buffered,
            defer: false)
        window.isReleasedWhenClosed = false
        field.frame = NSRect(x: 10, y: 20, width: 450, height: 32)
        window.contentView?.addSubview(field)
        window.makeFirstResponder(field)
        field.selectText(nil)
        return (window, field, coordinator, model)
    }

    private actor SiteSearchSuggestionRecorder {
        private(set) var count = 0

        func record(_ url: URL) { count += 1 }
    }
}
