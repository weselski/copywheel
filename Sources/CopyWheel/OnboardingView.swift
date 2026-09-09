import SwiftUI
import AppKit
import KeyboardShortcuts

struct OnboardingPreset: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let isSecret: Bool
    let placeholder: String
    var value = ""
}

/// Kleines Intro beim ersten Start: vorgeschlagene Snippets ausfüllen,
/// leere Felder werden übersprungen.
struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var presets = [
        OnboardingPreset(title: "E-Mail", icon: "envelope", isSecret: false, placeholder: "max@example.com"),
        OnboardingPreset(title: "Telefon", icon: "phone", isSecret: false, placeholder: "+49 123 4567890"),
        OnboardingPreset(title: "Adresse", icon: "house", isSecret: false, placeholder: "Musterstraße 1, 12345 Musterstadt"),
        OnboardingPreset(title: "Token", icon: "key", isSecret: true, placeholder: "API-Token o. Ä."),
        OnboardingPreset(title: "Passwort", icon: "lock", isSecret: true, placeholder: "Geheimnis"),
    ]

    private var shortcutHint: String {
        KeyboardShortcuts.getShortcut(for: .toggleWheel).map(String.init(describing:)) ?? "⌃⌥C"
    }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.accentColor)
                Text("Willkommen bei CopyWheel")
                    .font(.title2.bold())
                Text("Fülle aus, was du oft in die Zwischenablage kopierst – leere Felder werden übersprungen. Alles lässt sich später in den Einstellungen ändern und erweitern.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 8) {
                ForEach($presets) { $preset in
                    HStack(spacing: 10) {
                        Image(systemName: preset.icon)
                            .frame(width: 22)
                            .foregroundStyle(.secondary)
                        Text(preset.title)
                            .frame(width: 80, alignment: .leading)
                        if preset.isSecret {
                            SecureField(preset.placeholder, text: $preset.value)
                            Image(systemName: "lock.shield")
                                .foregroundStyle(.secondary)
                                .help("Wird sicher im macOS-Schlüsselbund gespeichert, nicht auf der Festplatte")
                        } else {
                            TextField(preset.placeholder, text: $preset.value)
                        }
                    }
                }
            }
            .textFieldStyle(.roundedBorder)

            Text("Geheime Einträge (🔒) landen im macOS-Schlüsselbund.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            VStack(spacing: 10) {
                Text("Drücke **\(shortcutHint)**, um das Rad an deinem Mauszeiger zu öffnen. Tipp: Belege eine Sondertaste deiner Maus mit diesem Kürzel.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Los geht's") { finish() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .padding(24)
        .frame(width: 470)
    }

    private func finish() {
        let newSnippets = presets
            .filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { Snippet(title: $0.title, text: $0.value, isSecret: $0.isSecret) }
        if !newSnippets.isEmpty {
            SnippetStore.shared.snippets.append(contentsOf: newSnippets)
        }
        onFinish()
    }
}

final class OnboardingWindowController {
    static let shared = OnboardingWindowController()
    private var window: NSWindow?

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: .zero,
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "CopyWheel"
            window.contentView = NSHostingView(rootView: OnboardingView { [weak self] in
                self?.close()
                // Direkt zeigen, wie sich das Rad anfühlt
                if !SnippetStore.shared.snippets.isEmpty {
                    WheelController.shared.show()
                }
            })
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private func close() {
        window?.orderOut(nil)
        window = nil
    }
}
