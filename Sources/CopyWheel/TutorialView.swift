import SwiftUI
import KeyboardShortcuts

/// Kurzes Tutorial beim ersten Start, als Sheet über den Einstellungen –
/// damit man direkt sieht, wo die eigenen Snippets hingehören.
struct TutorialView: View {
    /// Wird mit der Entscheidung für "Bei Anmeldung starten" aufgerufen.
    let onFinish: (_ launchAtLogin: Bool) -> Void

    @State private var launchAtLogin = true

    private var shortcutHint: String {
        KeyboardShortcuts.getShortcut(for: .toggleWheel).map(String.init(describing:)) ?? "⌃⌥C"
    }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accentColor)
                Text("Willkommen bei CopyWheel")
                    .font(.title2.bold())
                Text("Deine Texte, einen Tastendruck entfernt.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                step("keyboard", "Drücke **\(shortcutHint)** – das Rad erscheint an deinem Mauszeiger. Tipp: Belege eine Sondertaste deiner Maus mit diesem Kürzel.")
                step("cursorarrow.click.2", "Klick ein Segment an (oder **1–9**, bzw. **Pfeiltasten** + **↩**) – der Text liegt in der Zwischenablage, einfügen mit **⌘V**.")
                step("square.and.pencil", "Lege in den Einstellungen deine eigenen Snippets an. Geheime Einträge (🔒) landen im macOS-Schlüsselbund.")
                step("clock.arrow.circlepath", "Der äußere Ring zeigt die letzten \(ClipboardHistory.limit) Dinge, die du kopiert hast.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            HStack {
                Toggle("Bei Anmeldung automatisch starten", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                Spacer()
                Button("Los geht's") { onFinish(launchAtLogin) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    private func step(_ icon: String, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
