import AppKit
import ScreenCaptureKit
import SwiftUI
import XCTest

@testable import Crest

@MainActor
final class BrowserSiteSearchPresentationTests: XCTestCase {
    func testNativeSiteSearchSurfacesInLightAndDarkAppearances() async throws {
        let originalAppearance = NSApp.appearance
        defer { NSApp.appearance = originalAppearance }
        for scheme in [ColorScheme.light, .dark] {
            NSApp.appearance = NSAppearance(named: scheme == .light ? .aqua : .darkAqua)
            let model = BrowserCommandPalettePreviewFixture.model(query: "")
            model.updateCompletionEditing(
                text: "google", selection: NSRange(location: 6, length: 0), isComposing: false)
            XCTAssertTrue(model.acceptSiteSearch())
            model.query = "Crest browser"
            let content = VStack(spacing: 20) {
                SiteSearchPresentationPalette(model: model)
                HStack {
                    ForEach(BrowserSiteSearch.builtIn.suffix(3)) { site in
                        BrowserSiteSearchPill(site: site, showsCloseControl: true)
                    }
                }
                BrowserSettingsPane(.tabs) {
                    BrowserSiteSearchSettingsSection(
                        store: BrowserSiteSearchStore(entries: Array(BrowserSiteSearch.builtIn.prefix(3))))
                }
                BrowserSiteSearchEditor(entry: BrowserSiteSearch.builtIn[0], isNew: false, save: { _ in })
            }
            .padding(24)
            .frame(width: 640)
            .background(BrowserSettingsCanvas.background)
            .environment(\.colorScheme, scheme)
            let host = NSHostingView(rootView: content)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 640, height: 1100), styleMask: .borderless,
                backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.appearance = NSAppearance(named: scheme == .light ? .aqua : .darkAqua)
            window.contentView = host
            defer { window.close() }
            window.orderBack(nil)
            try await Task.sleep(for: .milliseconds(500))
            host.layoutSubtreeIfNeeded()
            host.displayIfNeeded()
            XCTAssertEqual(model.query, "Crest browser")
            XCTAssertEqual(model.activeSiteSearch?.name, "Google")
            let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: bitmap)
            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
            var colors = Set<Int>()
            let expectedColors = [BrowserSiteSearch.builtIn[0].color, BrowserSiteSearch.builtIn[1].color]
            var brandPixels = [0, 0]
            for x in stride(from: 0, to: bitmap.pixelsWide, by: 2) {
                for y in stride(from: 0, to: bitmap.pixelsHigh, by: 2) {
                    if let pixel = bitmap.colorAt(x: x, y: y) {
                        // AppKit samples omit the bitmap's embedded display profile.
                        let components = [
                            pixel.redComponent, pixel.greenComponent, pixel.blueComponent, pixel.alphaComponent,
                        ]
                        let profiled = NSColor(colorSpace: bitmap.colorSpace, components: components, count: 4)
                        let color = try XCTUnwrap(profiled.usingColorSpace(.sRGB))
                        colors.insert(
                            Int(color.redComponent * 255) << 16
                                | Int(color.greenComponent * 255) << 8
                                | Int(color.blueComponent * 255))
                        for (index, expected) in expectedColors.enumerated() {
                            if abs(color.redComponent - expected.red)
                                + abs(color.greenComponent - expected.green)
                                + abs(color.blueComponent - expected.blue) < 0.12
                            {
                                brandPixels[index] += 1
                            }
                        }
                    }

                }
            }
            XCTAssertGreaterThan(colors.count, 20, "The hosted view must render controls, not a blank surface.")
            for count in brandPixels {
                XCTAssertGreaterThan(count, 5, "Site search color accents must remain visible in both appearances.")
            }
            let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
            attachment.name = scheme == .light ? "Site searches - light" : "Site searches - dark"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testHaloPolicyHonorsAccessibilityDisplayPreferences() {
        XCTAssertTrue(BrowserSiteSearchGlow.showsHalo(reduceTransparency: false, contrast: .standard))
        XCTAssertFalse(BrowserSiteSearchGlow.showsHalo(reduceTransparency: true, contrast: .standard))
        XCTAssertFalse(BrowserSiteSearchGlow.showsHalo(reduceTransparency: false, contrast: .increased))
        XCTAssertFalse(BrowserSiteSearchGlow.showsHalo(reduceTransparency: true, contrast: .increased))
    }

    func testColoredGlowRendersOutsideTheSurfaceAndIncreasedContrastRemovesIt() async throws {
        guard CGPreflightScreenCaptureAccess() else {
            throw XCTSkip("Composited glow verification requires existing screen capture permission.")
        }
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency else {
            throw XCTSkip("Reduce Transparency intentionally suppresses the decorative halo.")
        }
        let plain = try await renderGlow(color: nil, contrast: .standard)
        let glowing = try await renderGlow(color: BrowserSiteSearch.builtIn[0].color, contrast: .standard)
        let highContrastPlain = try await renderGlow(color: nil, contrast: .increased)
        let highContrast = try await renderGlow(color: BrowserSiteSearch.builtIn[0].color, contrast: .increased)
        var glowPixels = 0
        var highContrastGlowPixels = 0
        for x in 0..<plain.pixelsWide {
            for y in 0..<plain.pixelsHigh {
                let point = CGPoint(
                    x: Double(x) / Double(plain.pixelsWide) * 244,
                    y: Double(y) / Double(plain.pixelsHigh) * 124)
                guard !CGRect(x: 30, y: 30, width: 184, height: 64).contains(point) else { continue }
                let baseline = try XCTUnwrap(plain.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
                let colored = try XCTUnwrap(glowing.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
                let accessibleBaseline = try XCTUnwrap(
                    highContrastPlain.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
                let accessible = try XCTUnwrap(highContrast.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
                func differs(_ color: NSColor, from baseline: NSColor) -> Bool {
                    abs(color.redComponent - baseline.redComponent)
                        + abs(color.greenComponent - baseline.greenComponent)
                        + abs(color.blueComponent - baseline.blueComponent) > 0.02
                }
                if differs(colored, from: baseline) { glowPixels += 1 }
                if differs(accessible, from: accessibleBaseline) { highContrastGlowPixels += 1 }
            }
        }
        XCTAssertGreaterThan(glowPixels, 100, "The active search must have a visible halo outside the palette.")
        XCTAssertEqual(highContrastGlowPixels, 0, "Increased Contrast replaces the halo with a solid border.")
    }

    private func renderGlow(color: BrandColor?, contrast: ColorSchemeContrast) async throws -> NSBitmapImageRep {
        let originalAppearance = NSApp.appearance
        defer { NSApp.appearance = originalAppearance }
        let appearance = NSAppearance(named: contrast == .increased ? .accessibilityHighContrastAqua : .aqua)
        NSApp.appearance = appearance
        let content = RoundedRectangle(cornerRadius: BrowserCommandPaletteMetrics.cardCornerRadius)
            .fill(Color(nsColor: .windowBackgroundColor))
            .frame(width: 180, height: 60)
            .modifier(BrowserSiteSearchGlow(color: color))
            .padding(32)
            .background(Color(nsColor: .windowBackgroundColor))
        let host = NSHostingView(rootView: content)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 244, height: 124), styleMask: .borderless,
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = appearance
        window.contentView = host
        defer { window.close() }
        window.orderBack(nil)
        try await Task.sleep(for: .milliseconds(200))
        host.layoutSubtreeIfNeeded()
        host.displayIfNeeded()
        let shareable = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        let sharedWindow = try XCTUnwrap(shareable.windows.first { $0.windowID == CGWindowID(window.windowNumber) })
        let configuration = SCStreamConfiguration()
        configuration.width = 244
        configuration.height = 124
        configuration.showsCursor = false
        configuration.ignoreShadowsSingleWindow = true
        // NSView's bitmap cache omits the blur composited by the window server.
        let image = try await SCScreenshotManager.captureImage(
            contentFilter: SCContentFilter(desktopIndependentWindow: sharedWindow), configuration: configuration)
        return NSBitmapImageRep(cgImage: image)
    }
}

private struct SiteSearchPresentationPalette: View {
    let model: BrowserCommandPaletteModel
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 12) {
            BrowserCommandPaletteSearchField(model: model, presentation: .embedded, queryIsFocused: $focused)
            if let item = model.items.first {
                BrowserCommandPaletteIntentRow(model: model, item: item)
            }
        }
        .padding()
        .background(.background, in: .rect(cornerRadius: 16))
        .modifier(BrowserSiteSearchGlow(color: model.activeSiteSearch?.color))
    }
}
