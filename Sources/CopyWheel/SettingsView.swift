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
    @ObservedObject var history = ClipboardHistory.shared
    @AppStorage(ClipboardHistory.enabledKey) private var historyEnabled = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State var showsTutorial = false

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
                .overlay {
                    if store.snippets.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "text.badge.plus")
                                .font(.title2)
                            Text("Noch keine Snippets – leg los mit „Snippet hinzufügen“.")
                                .font(.callout)
                        }
                        .foregroundStyle(.secondary)
                        .allowsHitTesting(false)
                    }
                }

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

            GroupBox("Verlauf") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle("Letzte \(ClipboardHistory.limit) Kopien als äußeren Ring anzeigen", isOn: $historyEnabled)
                            .onChange(of: historyEnabled) { _ in
                                history.updateMonitoring()
                            }
                        Spacer()
                        Button("Leeren") { history.clear() }
                            .disabled(history.entries.isEmpty)
                    }
                    Text("Merkt sich auch, was du in anderen Apps mit ⌘C kopierst – nur im Speicher, nie auf der Festplatte. Passwortmanager-Einträge werden ignoriert.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
            }

            Toggle("Bei Anmeldung starten", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { enabled in
                    setLaunchAtLogin(enabled)
                }
        }
        .padding(16)
        .frame(width: 520, height: 580)
        .sheet(isPresented: $showsTutorial) {
            TutorialView { enabled in
                launchAtLogin = enabled
                setLaunchAtLogin(enabled)
                showsTutorial = false
            }
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
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

final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    /// - Parameter tutorial: zeigt beim ersten Start das Tutorial als Sheet.
    func show(tutorial: Bool = false) {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 580),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "CopyWheel – Einstellungen"
            window.contentView = NSHostingView(rootView: SettingsView(showsTutorial: tutorial))
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
