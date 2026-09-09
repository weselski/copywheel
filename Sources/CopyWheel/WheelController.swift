import AppKit
import SwiftUI

/// Zeigt das Rad als randloses, nicht-aktivierendes Panel am Mauszeiger.
final class WheelController {
    static let shared = WheelController()

    private var panel: WheelPanel?
    private let wheelSize: CGFloat = 340

    var isVisible: Bool { panel != nil }

    func toggle() {
        isVisible ? hide() : show()
    }

    func show() {
        guard panel == nil else { return }

        let snippets = SnippetStore.shared.snippets
        guard !snippets.isEmpty else {
            SettingsWindowController.shared.show()
            return
        }

        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        var origin = NSPoint(x: mouse.x - wheelSize / 2, y: mouse.y - wheelSize / 2)
        if let visible = screen?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX), visible.maxX - wheelSize)
            origin.y = min(max(origin.y, visible.minY), visible.maxY - wheelSize)
        }

        let panel = WheelPanel(
            contentRect: NSRect(origin: origin, size: NSSize(width: wheelSize, height: wheelSize)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false

        let view = WheelView(
            snippets: snippets,
            onSelect: { [weak self] snippet in self?.copyAndClose(snippet) },
            onDismiss: { [weak self] in self?.hide() }
        )
        panel.contentView = NSHostingView(rootView: view)

        panel.onKeyDown = { [weak self] event in
            self?.handleKey(event, snippets: snippets) ?? false
        }
        panel.onResignKey = { [weak self] in self?.hide() }

        self.panel = panel
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.onResignKey = nil
        panel?.orderOut(nil)
        panel = nil
    }

    private func handleKey(_ event: NSEvent, snippets: [Snippet]) -> Bool {
        if event.keyCode == 53 { // Escape
            hide()
            return true
        }
        if let chars = event.charactersIgnoringModifiers,
           let digit = Int(chars), digit >= 1, digit <= min(snippets.count, 9) {
            copyAndClose(snippets[digit - 1])
            return true
        }
        return false
    }

    private func copyAndClose(_ snippet: Snippet) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(snippet.text, forType: .string)

        // Kurz das "Kopiert!"-Feedback stehen lassen, dann schließen.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.hide()
        }
    }
}

/// Panel, das Key-Events annehmen kann, ohne die App zu aktivieren.
final class WheelPanel: NSPanel {
    var onKeyDown: ((NSEvent) -> Bool)?
    var onResignKey: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if onKeyDown?(event) != true {
            super.keyDown(with: event)
        }
    }

    override func resignKey() {
        super.resignKey()
        onResignKey?()
    }
}
