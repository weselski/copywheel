import AppKit
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "circle.grid.cross",
            accessibilityDescription: "CopyWheel"
        )

        let menu = NSMenu()
        menu.addItem(withTitle: "Rad öffnen", action: #selector(openWheel), keyEquivalent: "")
        menu.addItem(withTitle: "Einstellungen…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "CopyWheel beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
        self.statusItem = statusItem

        KeyboardShortcuts.onKeyDown(for: .toggleWheel) {
            WheelController.shared.toggle()
        }

        // Intro beim allerersten Start (bzw. erzwungen via --onboarding zum Testen)
        let needsOnboarding = SnippetStore.shared.isFirstLaunch
            && !UserDefaults.standard.bool(forKey: "didShowOnboarding")
        if needsOnboarding || CommandLine.arguments.contains("--onboarding") {
            UserDefaults.standard.set(true, forKey: "didShowOnboarding")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                OnboardingWindowController.shared.show()
            }
        }

        // Für Entwicklung/Tests: `CopyWheel --settings` öffnet direkt die Einstellungen.
        if CommandLine.arguments.contains("--settings") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                SettingsWindowController.shared.show()
            }
        }

        // Für Entwicklung/Tests: `CopyWheel --demo` zeigt das Rad sofort an.
        if CommandLine.arguments.contains("--demo") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                WheelController.shared.show()
            }
        }
    }

    @objc private func openWheel() {
        WheelController.shared.show()
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
