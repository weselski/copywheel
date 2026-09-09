import SwiftUI
import AppKit

/// Geometrie des Rads an einer Stelle, damit Zeichnung (SwiftUI) und
/// Hit-Testing (AppKit, im Controller) garantiert übereinstimmen.
enum WheelLayout {
    static let size: CGFloat = 340
    static let inset: CGFloat = 6
    static let innerRatio: CGFloat = 0.38

    /// Segment unter dem Punkt (Panel-Koordinaten, Ursprung oben links,
    /// y nach unten). nil für die Mitte und außerhalb des Rings.
    static func index(at point: CGPoint, count: Int) -> Int? {
        guard count > 0 else { return nil }
        let center = size / 2
        let dx = point.x - center
        let dy = point.y - center
        let distance = sqrt(dx * dx + dy * dy)
        let radius = (size - inset * 2) / 2
        guard distance >= radius * innerRatio, distance <= radius else { return nil }

        let segment = 360.0 / Double(count)
        // atan2 im y-nach-unten-Koordinatensystem, 0° = rechts; Segment 0
        // ist um -90° (oben) zentriert.
        var degrees = atan2(dy, dx) * 180 / .pi
        degrees = (degrees + 90 + segment / 2).truncatingRemainder(dividingBy: 360)
        if degrees < 0 { degrees += 360 }
        let index = Int(degrees / segment)
        return (0..<count).contains(index) ? index : nil
    }
}

/// Vom Controller gefütterter UI-Zustand des Rads.
final class WheelState: ObservableObject {
    @Published var hoveredIndex: Int? = nil
    @Published var copiedIndex: Int? = nil
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

/// Das radiale Menü: Frosted-Glass-Donut mit einem Segment pro Snippet.
/// Rein visuell – Maus-Handling übernimmt der WheelController über
/// ein NSTrackingArea, weil SwiftUI-Hover in nicht-aktivierenden
/// Panels unzuverlässig ist.
struct WheelView: View {
    let snippets: [Snippet]
    @ObservedObject var state: WheelState

    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2
            let count = max(snippets.count, 1)
            let segment = 360.0 / Double(count)

            ZStack {
                // Frosted-Glass-Grundfläche
                VisualEffectView(material: .hudWindow)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.14), lineWidth: 1))

                ForEach(Array(snippets.enumerated()), id: \.element.id) { index, snippet in
                    let start = Angle(degrees: -90 - segment / 2 + Double(index) * segment)
                    let end = Angle(degrees: start.degrees + segment)
                    let mid = Angle(degrees: (start.degrees + end.degrees) / 2)
                    let labelRadius = radius * (1 + WheelLayout.innerRatio) / 2
                    let isHovered = state.hoveredIndex == index
                    let isCopied = state.copiedIndex == index
                    let pop: CGFloat = (isHovered || isCopied) ? 5 : 0
                    let popX = cos(mid.radians) * pop
                    let popY = sin(mid.radians) * pop

                    Group {
                        PieSlice(start: start, end: end, innerRatio: WheelLayout.innerRatio)
                            .fill(sliceStyle(hovered: isHovered, copied: isCopied))
                            .overlay(
                                PieSlice(start: start, end: end, innerRatio: WheelLayout.innerRatio)
                                    .stroke(Color.primary.opacity(0.10), lineWidth: 0.5)
                            )
                            .shadow(
                                color: glowColor(hovered: isHovered, copied: isCopied),
                                radius: 10
                            )

                        VStack(spacing: 2) {
                            if index < 9 {
                                Text("\(index + 1)")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(isHovered || isCopied ? Color.white.opacity(0.75) : Color.secondary)
                            }
                            Text(snippet.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(isHovered || isCopied ? Color.white : Color.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: radius * 0.55)
                        }
                        .scaleEffect(isHovered ? 1.06 : 1.0)
                        .position(
                            x: geo.size.width / 2 + cos(mid.radians) * labelRadius,
                            y: geo.size.height / 2 + sin(mid.radians) * labelRadius
                        )
                    }
                    .offset(x: popX, y: popY)
                    .animation(.spring(response: 0.22, dampingFraction: 0.7), value: state.hoveredIndex)
                    .animation(.spring(response: 0.22, dampingFraction: 0.7), value: state.copiedIndex)
                }

                centerCircle(radius: radius)
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
        }
        .padding(WheelLayout.inset)
    }

    private func centerCircle(radius: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.55))
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.14), lineWidth: 1))

            if let index = state.copiedIndex ?? state.hoveredIndex, snippets.indices.contains(index) {
                VStack(spacing: 4) {
                    if state.copiedIndex != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                        Text("Kopiert!")
                            .font(.system(size: 12, weight: .semibold))
                    } else {
                        Text(snippets[index].title)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                        Text(snippets[index].isSecret ? String(repeating: "•", count: 8) : snippets[index].text)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(6)
                .frame(maxWidth: radius * 2 * WheelLayout.innerRatio - 12)
                .animation(.spring(response: 0.22, dampingFraction: 0.7), value: state.copiedIndex)
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
        .frame(
            width: radius * 2 * WheelLayout.innerRatio - 8,
            height: radius * 2 * WheelLayout.innerRatio - 8
        )
    }

    private func sliceStyle(hovered: Bool, copied: Bool) -> AnyShapeStyle {
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
        return AnyShapeStyle(Color.primary.opacity(0.035))
    }

    private func glowColor(hovered: Bool, copied: Bool) -> Color {
        if copied { return Color.green.opacity(0.5) }
        if hovered { return Color.accentColor.opacity(0.5) }
        return .clear
    }
}

struct PieSlice: Shape {
    let start: Angle
    let end: Angle
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let inner = radius * innerRatio
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        path.addArc(center: center, radius: inner, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }
}
