import Foundation

struct Snippet: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var text: String
}

/// Lädt und speichert Snippets als JSON unter
/// ~/Library/Application Support/CopyWheel/snippets.json
final class SnippetStore: ObservableObject {
    static let shared = SnippetStore()

    @Published var snippets: [Snippet] {
        didSet { save() }
    }

    private let fileURL: URL

    private init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CopyWheel", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("snippets.json")

        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([Snippet].self, from: data) {
            snippets = decoded
        } else {
            snippets = [
                Snippet(title: "E-Mail", text: "max@example.com"),
                Snippet(title: "Telefon", text: "+49 123 4567890"),
                Snippet(title: "Adresse", text: "Musterstraße 1, 12345 Musterstadt"),
                Snippet(title: "Grußformel", text: "Viele Grüße\nMax Mustermann"),
            ]
            save()
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(snippets) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
