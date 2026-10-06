import Foundation

struct BrowserSiteSearch: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var shortcut: String
    var template: String
    var aliases: [String] = []
    var color: BrandColor = .folderDefault

    static func new() -> Self {
        Self(id: UUID(), name: "", shortcut: "", template: "")
    }

    var host: String {
        URL(string: template.replacingOccurrences(of: "%s", with: "search"))?.host ?? ""
    }

    var shortcuts: [String] { [shortcut] + aliases }

    func validated() throws -> Self {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let shortcut = shortcut.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let aliases = aliases.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let template = template.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "{searchTerms}", with: "%s")
        guard !name.isEmpty else { throw BrowserSiteSearchError.missingName }
        guard
            ([shortcut] + aliases).allSatisfy({
                !$0.isEmpty && !$0.contains(where: { $0.isWhitespace }) && !$0.contains("/") && !$0.contains(":")
            })
        else { throw BrowserSiteSearchError.invalidShortcut }
        guard Set([shortcut] + aliases).count == aliases.count + 1 else {
            throw BrowserSiteSearchError.duplicateShortcut
        }
        let marker = "crest-site-search-terms"
        guard template.components(separatedBy: "%s").count == 2,
            let components = URLComponents(string: template.replacingOccurrences(of: "%s", with: marker)),
            components.scheme?.lowercased() == "https",
            let host = components.host, !host.isEmpty, !host.contains(marker),
            components.user == nil, components.password == nil,
            !(components.fragment?.contains(marker) ?? false), components.url != nil
        else { throw BrowserSiteSearchError.invalidTemplate }
        return Self(
            id: id, name: name, shortcut: shortcut, template: template, aliases: aliases,
            color: BrandColor(clampingRed: color.red, green: color.green, blue: color.blue, alpha: 1))
    }

    func url(for query: String) -> URL? {
        let words = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !words.isEmpty else { return nil }
        let unreserved = CharacterSet(
            charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        guard let encoded = words.addingPercentEncoding(withAllowedCharacters: unreserved) else { return nil }
        return URL(string: template.replacingOccurrences(of: "%s", with: encoded))
    }

    static let builtIn: [Self] = [
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000001")!, name: "Google", shortcut: "google",
            template: "https://www.google.com/search?q=%s", aliases: ["g"], color: tint(0x4285F4)),
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000002")!, name: "YouTube", shortcut: "yt",
            template: "https://www.youtube.com/results?search_query=%s", color: tint(0xFF0000)),
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000003")!, name: "Wikipedia", shortcut: "wiki",
            template: "https://\(wikipediaLanguage).wikipedia.org/w/index.php?search=%s", color: tint(0x636466)),
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000004")!, name: "GitHub", shortcut: "gh",
            template: "https://github.com/search?q=%s", color: tint(0x8250DF)),
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000005")!, name: "Reddit", shortcut: "reddit",
            template: "https://www.reddit.com/search/?q=%s", color: tint(0xFF4500)),
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000006")!, name: "X", shortcut: "x",
            template: "https://x.com/search?q=%s", aliases: ["twitter"], color: tint(0x111111)),
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000007")!, name: "ChatGPT", shortcut: "chatgpt",
            template: "https://chatgpt.com/?q=%s", aliases: ["gpt", "openai"], color: tint(0x10A37F)),
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000008")!, name: "Claude", shortcut: "claude",
            template: "https://claude.ai/new?q=%s", color: tint(0xD97757)),
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000009")!, name: "Perplexity",
            shortcut: "perplexity", template: "https://www.perplexity.ai/search?q=%s", color: tint(0x20B8CD)),
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000010")!, name: "Stack Overflow", shortcut: "so",
            template: "https://stackoverflow.com/search?q=%s", color: tint(0xF48024)),
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000011")!, name: "MDN", shortcut: "mdn",
            template: "https://developer.mozilla.org/search?q=%s", color: tint(0x83D0F2)),
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000012")!, name: "Amazon", shortcut: "amazon",
            template: "https://www.\(amazonHost)/s?k=%s", color: tint(0xFF9900)),
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000013")!, name: "IMDb", shortcut: "imdb",
            template: "https://www.imdb.com/find/?q=%s", color: tint(0xF5C518)),
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000014")!, name: "Spotify", shortcut: "spotify",
            template: "https://open.spotify.com/search/%s", color: tint(0x1DB954)),
        Self(
            id: UUID(uuidString: "8ACD9711-0BEB-4B1B-90D2-000000000015")!, name: "Figma Community",
            shortcut: "figma",
            template: "https://www.figma.com/community/search?resource_type=mixed&sort_by=relevancy&query=%s",
            color: tint(0xF24E1E)),
    ]

    private static func tint(_ hex: UInt32) -> BrandColor {
        BrandColor(
            red: Double((hex >> 16) & 255) / 255,
            green: Double((hex >> 8) & 255) / 255,
            blue: Double(hex & 255) / 255)
    }

    private static var wikipediaLanguage: String {
        let language =
            Locale.preferredLanguages.first.map {
                Locale(identifier: $0).language.languageCode?.identifier ?? "en"
            } ?? "en"
        return language.allSatisfy(\.isLetter) && language.count <= 3 ? language : "en"
    }

    private static var amazonHost: String {
        switch Locale.current.region?.identifier {
        case "FR": "amazon.fr"
        case "DE", "AT": "amazon.de"
        case "GB", "IE": "amazon.co.uk"
        case "IT": "amazon.it"
        case "ES": "amazon.es"
        case "NL": "amazon.nl"
        case "BE": "amazon.com.be"
        case "JP": "amazon.co.jp"
        case "CA": "amazon.ca"
        case "AU": "amazon.com.au"
        case "IN": "amazon.in"
        case "BR": "amazon.com.br"
        case "MX": "amazon.com.mx"
        default: "amazon.com"
        }
    }
}

extension BrowserSiteSearch {
    private enum CodingKeys: String, CodingKey {
        case id, name, shortcut, template, aliases, color
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        self.init(
            id: id,
            name: try container.decode(String.self, forKey: .name),
            shortcut: try container.decode(String.self, forKey: .shortcut),
            template: try container.decode(String.self, forKey: .template),
            aliases: try container.decodeIfPresent([String].self, forKey: .aliases) ?? [],
            color: try container.decodeIfPresent(BrandColor.self, forKey: .color)
                ?? Self.builtIn.first(where: { $0.id == id })?.color ?? .folderDefault)
    }
}

enum BrowserSiteSearchError: LocalizedError {
    case missingName
    case invalidShortcut
    case invalidTemplate
    case duplicateShortcut
    case unreadableStorage

    var errorDescription: String? {
        switch self {
        case .missingName: String(localized: "Enter a name for the site search.")
        case .invalidShortcut: String(localized: "Enter a shortcut without spaces, slashes, or colons.")
        case .invalidTemplate:
            String(localized: "Enter an HTTPS search URL with exactly one %s or {searchTerms} in its path or query.")
        case .duplicateShortcut: String(localized: "Another site search already uses this shortcut.")
        case .unreadableStorage:
            String(localized: "Saved site searches couldn’t be read. Restore the saved settings before making changes.")
        }
    }
}
