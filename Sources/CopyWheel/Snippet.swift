import Foundation

struct Snippet: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var text: String
    /// Geheime Snippets (Tokens, Passwörter) landen im Schlüsselbund,
    /// nicht in der JSON-Datei.
    var isSecret = false

    init(id: UUID = UUID(), title: String, text: String, isSecret: Bool = false) {
        self.id = id
        self.title = title
        self.text = text
        self.isSecret = isSecret
    }

    /// Beispieldaten für den Demo-Modus (--demo), damit Aufnahmen und
    /// Screenshots nie echte Nutzerdaten zeigen.
    static let demo: [Snippet] = [
        Snippet(title: "E-Mail", text: "max@example.com"),
        Snippet(title: "Telefon", text: "+49 123 4567890"),
        Snippet(title: "Adresse", text: "Musterstraße 1, 12345 Musterstadt"),
        Snippet(title: "Grußformel", text: "Viele Grüße\nMax"),
        Snippet(title: "API-Token", text: "demo-1234", isSecret: true),
    ]

    private enum CodingKeys: String, CodingKey { case id, title, text, isSecret }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        text = try container.decode(String.self, forKey: .text)
        // Fehlt in Dateien von v0.1.x
        isSecret = try container.decodeIfPresent(Bool.self, forKey: .isSecret) ?? false
    }
}

/// Lädt und speichert Snippets als JSON unter
/// ~/Library/Application Support/CopyWheel/snippets.json.
/// Texte von geheimen Snippets liegen im Schlüsselbund; in der JSON-Datei
/// steht für sie nur ein leerer Platzhalter.
final class SnippetStore: ObservableObject {
    static let shared = SnippetStore()

    @Published var snippets: [Snippet] {
        didSet { save() }
    }

    /// true, wenn beim Start noch keine snippets.json existierte.
    let isFirstLaunch: Bool

    private let fileURL: URL
    private var secretIDs: Set<String> = []

    private init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CopyWheel", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("snippets.json")

        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([Snippet].self, from: data) {
            isFirstLaunch = false
            snippets = decoded.map { snippet in
                var snippet = snippet
                if snippet.isSecret {
                    snippet.text = Keychain.get(snippet.id.uuidString) ?? ""
                }
                return snippet
            }
            secretIDs = Set(decoded.filter(\.isSecret).map { $0.id.uuidString })
        } else {
            isFirstLaunch = true
            snippets = []
        }
    }

    private func save() {
        // Schlüsselbund-Einträge gelöschter oder "entheimlichter" Snippets aufräumen
        let currentSecretIDs = Set(snippets.filter(\.isSecret).map { $0.id.uuidString })
        for removed in secretIDs.subtracting(currentSecretIDs) {
            Keychain.delete(removed)
        }
        secretIDs = currentSecretIDs

        let onDisk = snippets.map { snippet -> Snippet in
            guard snippet.isSecret else { return snippet }
            Keychain.set(snippet.text, for: snippet.id.uuidString)
            var placeholder = snippet
            placeholder.text = ""
            return placeholder
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(onDisk) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
