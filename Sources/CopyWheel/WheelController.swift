import AppKit
import SwiftUI

/// Zeigt das Rad als randloses, nicht-aktivierendes Panel am Mauszeiger.
/// Hover und Klicks werden über ein NSTrackingArea (.activeAlways) auf der
/// Hosting-View verarbeitet – SwiftUI-Hover-Modifier funktionieren in
/// nicht-aktivierenden Panels nicht zuverlässig.
final class WheelController {
    static let shared = WheelController()

    private var panel: WheelPanel?

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

        let wheelSize = WheelLayout.size
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
        panel.acceptsMouseMovedEvents = true

        let state = WheelState()
        let count = snippets.count
        let hosting = WheelHostingView(rootView: WheelView(snippets: snippets, state: state))

        hosting.onMouseMoved = { point in
            state.hoveredIndex = WheelLayout.index(at: point, count: count)
        }
        hosting.onMouseExited = {
            state.hoveredIndex = nil
        }
        hosting.onMouseDown = { [weak self] point in
            if let index = WheelLayout.index(at: point, count: count) {
                self?.select(index, snippets: snippets, state: state)
            } else {
                self?.hide()
            }
        }
        panel.contentView = hosting

        panel.onKeyDown = { [weak self] event in
            self?.handleKey(event, snippets: snippets, state: state) ?? false
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

    private func handleKey(_ event: NSEvent, snippets: [Snippet], state: WheelState) -> Bool {
        if event.keyCode == 53 { // Escape
            hide()
            return true
        }
        if let chars = event.charactersIgnoringModifiers,
           let digit = Int(chars), digit >= 1, digit <= min(snippets.count, 9) {
            select(digit - 1, snippets: snippets, state: state)
            return true
        }
        return false
    }

    private func select(_ index: Int, snippets: [Snippet], state: WheelState) {
        guard state.copiedIndex == nil, snippets.indices.contains(index) else { return }
        state.copiedIndex = index

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(snippets[index].text, forType: .string)

        // Kurz das "Kopiert!"-Feedback stehen lassen, dann schließen.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.hide()
        }
    }
}

/// Hosting-View mit eigenem Maus-Tracking (funktioniert unabhängig davon,
/// ob Fenster/App aktiv sind) in Panel-Koordinaten mit y nach unten.
final class WheelHostingView: NSHostingView<WheelView> {
    var onMouseMoved: ((CGPoint) -> Void)?
    var onMouseDown: ((CGPoint) -> Void)?
    var onMouseExited: (() -> Void)?

    private var trackingArea: NSTrackingArea?

    required init(rootView: WheelView) {
        super.init(rootView: rootView)
    }

    @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    private func location(of event: NSEvent) -> CGPoint {
        var point = convert(event.locationInWindow, from: nil)
        if !isFlipped {
            point.y = bounds.height - point.y
        }
        return point
    }

    override func mouseEntered(with event: NSEvent) { onMouseMoved?(location(of: event)) }
    override func mouseMoved(with event: NSEvent) { onMouseMoved?(location(of: event)) }
    override func mouseExited(with event: NSEvent) { onMouseExited?() }
    override func mouseDown(with event: NSEvent) { onMouseDown?(location(of: event)) }
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
