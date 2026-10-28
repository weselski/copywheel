import SwiftUI
import AppKit

/// Ein Eintrag im Rad – ein Snippet oder ein Text aus dem Verlauf.
struct WheelItem: Identifiable {
    let id: String
    /// Beschriftung im Ring
    let label: String
    /// Kopfzeile in der Mitte beim Hovern
    let title: String
    let text: String
    var isSecret = false
    var isHistory = false

    init(snippet: Snippet) {
        id = snippet.id.uuidString
        label = snippet.title
        title = snippet.title
        text = snippet.text
        isSecret = snippet.isSecret
    }

    init(historyText text: String, position: Int) {
        id = "history-\(position)"
        let firstLine = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty } ?? ""
        label = firstLine.count > 40 ? firstLine.prefix(40) + "…" : firstLine
        title = position == 0 ? "Zuletzt kopiert" : "Verlauf \(position + 1)"
        self.text = text
        isHistory = true
    }
}

/// Ein Segment im Rad: Ring (0 = innen) und Position im Ring.
struct WheelTarget: Equatable {
    let ring: Int
    let index: Int
}

/// Geometrie des Rads an einer Stelle, damit Zeichnung (SwiftUI) und
/// Hit-Testing (AppKit, im Controller) garantiert übereinstimmen.
struct WheelLayout {
    /// Transparenter Rand ums Rad, damit der Schatten nicht an den
    /// Fensterkanten abgeschnitten wird.
    static let inset: CGFloat = 40
    /// Radien je Ring von innen nach außen: Snippets, dann Verlauf.
    static let ringRadii: [(inner: CGFloat, outer: CGFloat)] = [(62, 164), (168, 250)]

    /// Anzahl Segmente je Ring
    let counts: [Int]

    var holeRadius: CGFloat { Self.ringRadii[0].inner }
    var outerRadius: CGFloat { Self.ringRadii[counts.count - 1].outer }
    var size: CGFloat { (outerRadius + Self.inset) * 2 }

    func radii(ring: Int) -> (inner: CGFloat, outer: CGFloat) { Self.ringRadii[ring] }

    /// Winkel der Segmentmitte; Segment 0 liegt oben, es geht im Uhrzeigersinn
    /// weiter (y nach unten).
    func midAngle(ring: Int, index: Int) -> Angle {
        Angle(degrees: -90 + Double(index) * 360 / Double(counts[ring]))
    }

    /// Segment unter dem Punkt (Panel-Koordinaten, Ursprung oben links,
    /// y nach unten). nil für die Mitte und außerhalb des Rads.
    func target(at point: CGPoint) -> WheelTarget? {
        let center = size / 2
        let dx = point.x - center
        let dy = point.y - center
        let distance = sqrt(dx * dx + dy * dy)
        // Der schmale Spalt zwischen zwei Ringen zählt zum äußeren.
        guard let ring = counts.indices.first(where: { distance <= radii(ring: $0).outer }),
              distance >= holeRadius,
              counts[ring] > 0
        else { return nil }

        let segment = 360.0 / Double(counts[ring])
        // atan2 im y-nach-unten-Koordinatensystem, 0° = rechts; Segment 0
        // ist um -90° (oben) zentriert.
        var degrees = atan2(dy, dx) * 180 / .pi
        degrees = (degrees + 90 + segment / 2).truncatingRemainder(dividingBy: 360)
        if degrees < 0 { degrees += 360 }
        let index = Int(degrees / segment)
        return (0..<counts[ring]).contains(index) ? WheelTarget(ring: ring, index: index) : nil
    }
}

/// Vom Controller gefütterter UI-Zustand des Rads.
final class WheelState: ObservableObject {
    @Published var hovered: WheelTarget? = nil
    @Published var copied: WheelTarget? = nil
    var isKeyboardNavigating = false
}

/// Echter macOS-Blur als Basis des Rads.
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}

/// Das radiale Menü: Frosted-Glass-Donut mit einem Ring pro Kategorie
/// (innen Snippets, außen Verlauf) und einem Segment pro Eintrag.
/// Rein visuell – Maus- und Tastatur-Handling übernimmt der
/// WheelController, weil SwiftUI-Hover in nicht-aktivierenden Panels
/// unzuverlässig ist.
struct WheelView: View {
    let rings: [[WheelItem]]
    @ObservedObject var state: WheelState

    @State private var appeared = false

    private var layout: WheelLayout { WheelLayout(counts: rings.map(\.count)) }

    var body: some View {
        let center = layout.size / 2 - WheelLayout.inset

        ZStack {
            // Frosted-Glass-Grundfläche
            VisualEffectView(material: .hudWindow)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.14), lineWidth: 1))

            ForEach(rings.indices, id: \.self) { ring in
                ForEach(Array(rings[ring].enumerated()), id: \.element.id) { index, item in
                    segment(item, target: WheelTarget(ring: ring, index: index), center: center)
                }
            }

            centerCircle
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.3), radius: 16, y: 5)
        .scaleEffect(appeared ? 1 : 0.82)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.72)) {
                appeared = true
            }
        }
        .padding(WheelLayout.inset)
    }

    private func segment(_ item: WheelItem, target: WheelTarget, center: CGFloat) -> some View {
        let count = rings[target.ring].count
        let segment = 360.0 / Double(count)
        let mid = layout.midAngle(ring: target.ring, index: target.index)
        let start = Angle(degrees: mid.degrees - segment / 2)
        let end = Angle(degrees: mid.degrees + segment / 2)
        let radii = layout.radii(ring: target.ring)
        let labelRadius = (radii.inner + radii.outer) / 2
        let arcLength = 2 * .pi * labelRadius / CGFloat(count)
        let isHovered = state.hovered == target
        let isCopied = state.copied == target
        let isActive = isHovered || isCopied
        let pop: CGFloat = isActive ? 5 : 0

        return Group {
            PieSlice(start: start, end: end, inner: radii.inner, outer: radii.outer)
                .fill(sliceStyle(hovered: isHovered, copied: isCopied, history: item.isHistory))
                .overlay(
                    PieSlice(start: start, end: end, inner: radii.inner, outer: radii.outer)
                        .stroke(Color.primary.opacity(0.10), lineWidth: 0.5)
                )
                .shadow(color: glowColor(hovered: isHovered, copied: isCopied), radius: 10)

            VStack(spacing: 2) {
                if item.isHistory {
                    Image(systemName: "clock")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(isActive ? Color.white.opacity(0.75) : Color.secondary)
                } else if target.ring == 0 && target.index < 9 {
                    Text("\(target.index + 1)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(isActive ? Color.white.opacity(0.75) : Color.secondary)
                }
                Text(item.label)
                    .font(.system(size: item.isHistory ? 10 : 12, weight: item.isHistory ? .medium : .semibold))
                    .foregroundStyle(isActive ? Color.white : Color.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: min(arcLength * 0.8, item.isHistory ? 100 : 90))
            }
            .scaleEffect(isHovered ? 1.06 : 1.0)
            .position(
                x: center + cos(mid.radians) * labelRadius,
                y: center + sin(mid.radians) * labelRadius
            )
        }
        .offset(x: cos(mid.radians) * pop, y: sin(mid.radians) * pop)
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: state.hovered)
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: state.copied)
    }

    private var centerCircle: some View {
        let diameter = layout.holeRadius * 2 - 8
        return ZStack {
            Circle()
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.55))
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.14), lineWidth: 1))

            if let target = state.copied ?? state.hovered, let item = item(at: target) {
                VStack(spacing: 4) {
                    if state.copied != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                        Text("Kopiert!")
                            .font(.system(size: 12, weight: .semibold))
                    } else {
                        Text(item.title)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                        Text(item.isSecret ? String(repeating: "•", count: 8) : item.text)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(6)
                .frame(maxWidth: diameter - 4)
                .animation(.spring(response: 0.22, dampingFraction: 0.7), value: state.copied)
            } else {
                VStack(spacing: 3) {
                    Image(systemName: "doc.on.doc")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("CopyWheel")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: diameter, height: diameter)
    }

    private func item(at target: WheelTarget) -> WheelItem? {
        guard rings.indices.contains(target.ring),
              rings[target.ring].indices.contains(target.index)
        else { return nil }
        return rings[target.ring][target.index]
    }

    private func sliceStyle(hovered: Bool, copied: Bool, history: Bool) -> AnyShapeStyle {
        if copied {
            return AnyShapeStyle(LinearGradient(
                colors: [Color.green, Color.green.opacity(0.7)],
                startPoint: .top, endPoint: .bottom
            ))
        }
        if hovered {
            return AnyShapeStyle(LinearGradient(
                colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                startPoint: .top, endPoint: .bottom
            ))
        }
        return AnyShapeStyle(Color.primary.opacity(history ? 0.015 : 0.035))
    }

    private func glowColor(hovered: Bool, copied: Bool) -> Color {
        if copied { return Color.green.opacity(0.5) }
        if hovered { return Color.accentColor.opacity(0.5) }
        return .clear
    }
}

/// Ringsegment mit absoluten Radien um die Mitte des Rechtecks.
struct PieSlice: Shape {
    let start: Angle
    let end: Angle
    let inner: CGFloat
    let outer: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(center: center, radius: outer, startAngle: start, endAngle: end, clockwise: false)
        path.addArc(center: center, radius: inner, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }
}
