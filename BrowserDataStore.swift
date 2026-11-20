import Foundation

enum NebulaTheme: String, Codable, CaseIterable {
    case violet
    case auroraBlue
    case cosmicRose

    var displayName: String {
        switch self {
        case .violet: return "Violet"
        case .auroraBlue: return "Aurora Blue"
        case .cosmicRose: return "Cosmic Rose"
        }
    }
}

struct BrowserTab: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String = "New Tab"
    var url: String = "https://duckduckgo.com/"
}

struct HistoryRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var url: String
    var visitedAt: Date = Date()
}

struct BookmarkRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var url: String
    var addedAt: Date = Date()
}

struct BrowserData: Codable {
    var tabs: [BrowserTab] = [BrowserTab()]
    var activeTabID: UUID?
    var history: [HistoryRecord] = []
    var bookmarks: [BookmarkRecord] = []
    var theme: NebulaTheme = .violet
    var animationsEnabled: Bool = true
    var glowIntensity: Double = 0.65

    mutating func normalize() {
        if tabs.isEmpty { tabs = [BrowserTab()] }
        if activeTabID == nil || !tabs.contains(where: { $0.id == activeTabID }) {
            activeTabID = tabs.first?.id
        }
        if history.count > 500 { history = Array(history.prefix(500)) }
    }
}

enum BrowserDataStore {
    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("NebulaBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("browser-data.json")
    }

    static func load() -> BrowserData {
        guard let data = try? Data(contentsOf: fileURL),
              var decoded = try? JSONDecoder().decode(BrowserData.self, from: data) else {
            var fresh = BrowserData()
            fresh.normalize()
            return fresh
        }
        decoded.normalize()
        return decoded
    }

    static func save(_ data: BrowserData) {
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("Nebula Browser: failed to save browser data: %@", error.localizedDescription)
        }
    }
}
