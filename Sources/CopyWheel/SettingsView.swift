import SwiftUI
import KeyboardShortcuts
import ServiceManagement

extension KeyboardShortcuts.Name {
    /// Standard: ⌃⌥C — auf der Maus-Sondertaste einfach diesen Shortcut hinterlegen
    /// (z. B. in Logi Options+ als Tastenkürzel-Aktion).
    static let toggleWheel = Self("toggleWheel", default: .init(.c, modifiers: [.control, .option]))
}

struct SettingsView: View {
    @ObservedObject var store = SnippetStore.shared
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Tastenkürzel") {
                VStack(alignment: .leading, spacing: 8) {
                    KeyboardShortcuts.Recorder("Rad öffnen:", name: .toggleWheel)
                    Text("Tipp: Belege die Sondertaste deiner Maus (z. B. in Logi Options+) mit genau diesem Tastenkürzel.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
            }

            GroupBox {
                List {
                    ForEach($store.snippets) { $snippet in
                        HStack(alignment: .top, spacing: 8) {
                            TextField("Titel", text: $snippet.title)
                                .frame(width: 140)
                            if snippet.isSecret {
                                SecureField("Text", text: $snippet.text)
                            } else {
                                TextField("Text", text: $snippet.text, axis: .vertical)
                                    .lineLimit(1...4)
                            }
                            Button {
                                snippet.isSecret.toggle()
                            } label: {
                                Image(systemName: snippet.isSecret ? "lock.fill" : "lock.open")
                                    .foregroundStyle(snippet.isSecret ? Color.accentColor : Color.secondary)
                            }
                            .buttonStyle(.plain)
                            .help(snippet.isSecret
                                ? "Wird im macOS-Schlüsselbund gespeichert"
                                : "Als Geheimnis im Schlüsselbund speichern")
                            Button {
                                store.snippets.removeAll { $0.id == snippet.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                    .onMove { indices, offset in
                        store.snippets.move(fromOffsets: indices, toOffset: offset)
                    }
                }
                .frame(minHeight: 220)

                HStack {
                    Button {
                        store.snippets.append(Snippet(title: "Neu", text: ""))
                    } label: {
                        Label("Snippet hinzufügen", systemImage: "plus")
                    }
                    Spacer()
                    Text("\(store.snippets.count) Snippets · im Rad am besten ≤ 8")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(6)
            } label: {
                Text("Snippets")
            }

            Toggle("Bei Anmeldung starten", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { enabled in
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }
        }
        .padding(16)
        .frame(width: 520, height: 480)
    }
}

final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "CopyWheel – Einstellungen"
            window.contentView = NSHostingView(rootView: SettingsView())
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
