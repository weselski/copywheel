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

        let isDemo = CommandLine.arguments.contains("--demo")
        let snippets = isDemo ? Snippet.demo : SnippetStore.shared.snippets
        let history = isDemo ? Snippet.demoHistory : ClipboardHistory.shared.entries
        let rings = [
            snippets.map(WheelItem.init(snippet:)),
            history.enumerated().map { WheelItem(historyText: $1, position: $0) },
        ].filter { !$0.isEmpty }
        guard !rings.isEmpty else {
            SettingsWindowController.shared.show()
            return
        }

        let layout = WheelLayout(counts: rings.map(\.count))
        let wheelSize = layout.size
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        var origin = NSPoint(x: mouse.x - wheelSize / 2, y: mouse.y - wheelSize / 2)
        // Der transparente Schattenrand darf über den Bildschirmrand ragen,
        // nur das Rad selbst muss sichtbar bleiben.
        if let visible = screen?.visibleFrame.insetBy(dx: -WheelLayout.inset, dy: -WheelLayout.inset) {
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
        // Schatten zeichnet die View selbst – Fensterschatten flackert
        // bei der Einblend-Animation.
        panel.hasShadow = false
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.acceptsMouseMovedEvents = true

        let state = WheelState()
        let hosting = WheelHostingView(rootView: WheelView(rings: rings, state: state))

        hosting.onMouseMoved = { point in
            // Nach Pfeiltasten-Navigation übernimmt die Maus erst wieder,
            // wenn sie auf ein Segment zeigt – leichtes Wackeln in der Mitte
            // soll die Auswahl nicht löschen.
            let target = layout.target(at: point)
            guard target != nil || !state.isKeyboardNavigating else { return }
            state.isKeyboardNavigating = false
            state.hovered = target
        }
        hosting.onMouseExited = {
            state.hovered = nil
        }
        hosting.onMouseDown = { [weak self] point in
            if let target = layout.target(at: point) {
                self?.select(target, rings: rings, state: state)
            } else {
                self?.hide()
            }
        }
        panel.contentView = hosting

        panel.onKeyDown = { [weak self] event in
            self?.handleKey(event, rings: rings, layout: layout, state: state) ?? false
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

    private func handleKey(_ event: NSEvent, rings: [[WheelItem]], layout: WheelLayout, state: WheelState) -> Bool {
        if [123, 124, 125, 126, 48].contains(event.keyCode) {
            state.isKeyboardNavigating = true
        }
        switch event.keyCode {
        case 53: // Escape
            hide()
        case 36, 76, 49: // Return, Enter, Leertaste
            guard let target = state.hovered else { return true }
            select(target, rings: rings, state: state)
        case 124: // →  im Uhrzeigersinn
            state.hovered = rotate(state.hovered, by: 1, layout: layout)
        case 123: // ←  gegen den Uhrzeigersinn
            state.hovered = rotate(state.hovered, by: -1, layout: layout)
        case 126: // ↑  in den äußeren Ring
            state.hovered = switchRing(state.hovered, by: 1, wrap: false, layout: layout)
        case 125: // ↓  in den inneren Ring
            state.hovered = switchRing(state.hovered, by: -1, wrap: false, layout: layout)
        case 48: // Tab  Ring wechseln
            state.hovered = switchRing(state.hovered, by: 1, wrap: true, layout: layout)
        default:
            if let chars = event.charactersIgnoringModifiers,
               let digit = Int(chars), digit >= 1, digit <= min(rings[0].count, 9) {
                select(WheelTarget(ring: 0, index: digit - 1), rings: rings, state: state)
                return true
            }
            return false
        }
        return true
    }

    private func rotate(_ current: WheelTarget?, by step: Int, layout: WheelLayout) -> WheelTarget {
        guard let current else { return WheelTarget(ring: 0, index: 0) }
        let count = layout.counts[current.ring]
        return WheelTarget(ring: current.ring, index: (current.index + step + count) % count)
    }

    /// Wechselt den Ring und landet auf dem Segment, das dem bisherigen
    /// am nächsten liegt.
    private func switchRing(_ current: WheelTarget?, by step: Int, wrap: Bool, layout: WheelLayout) -> WheelTarget {
        guard let current else { return WheelTarget(ring: 0, index: 0) }
        let ringCount = layout.counts.count
        var ring = current.ring + step
        if wrap {
            ring = (ring + ringCount) % ringCount
        } else {
            ring = min(max(ring, 0), ringCount - 1)
        }
        guard ring != current.ring else { return current }
        let fraction = Double(current.index) / Double(layout.counts[current.ring])
        let count = layout.counts[ring]
        return WheelTarget(ring: ring, index: Int((fraction * Double(count)).rounded()) % count)
    }

    private func select(_ target: WheelTarget, rings: [[WheelItem]], state: WheelState) {
        guard state.copied == nil,
              rings.indices.contains(target.ring),
              rings[target.ring].indices.contains(target.index)
        else { return }
        state.copied = target

        // Verlaufseinträge rutschen beim Kopieren wieder nach vorn, Snippets
        // landen nicht im Verlauf – die hat man ja schon im Rad.
        let item = rings[target.ring][target.index]
        ClipboardHistory.shared.copy(item.text, isSecret: item.isSecret, remember: item.isHistory)

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

    // Tasten schon hier abfangen – sonst schluckt die Hosting-View
    // Pfeiltasten und Tab für ihre eigene Fokus-Navigation.
    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, onKeyDown?(event) == true {
            return
        }
        super.sendEvent(event)
    }

    override func resignKey() {
        super.resignKey()
        onResignKey?()
    }
}
