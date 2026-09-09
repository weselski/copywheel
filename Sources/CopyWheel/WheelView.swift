import SwiftUI

/// Das radiale Menü: ein Donut aus Segmenten, eines pro Snippet.
/// Klick auf ein Segment (oder Taste 1–9) kopiert das Snippet.
struct WheelView: View {
    let snippets: [Snippet]
    let onSelect: (Snippet) -> Void
    let onDismiss: () -> Void

    @State private var hoveredIndex: Int? = nil
    @State private var copiedIndex: Int? = nil

    private let innerRatio: CGFloat = 0.38

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let count = max(snippets.count, 1)
            let segment = 360.0 / Double(count)

            ZStack {
                ForEach(Array(snippets.enumerated()), id: \.element.id) { index, snippet in
                    let start = Angle(degrees: -90 - segment / 2 + Double(index) * segment)
                    let end = Angle(degrees: start.degrees + segment)
                    let mid = Angle(degrees: (start.degrees + end.degrees) / 2)
                    let labelRadius = radius * (1 + innerRatio) / 2
                    let isHovered = hoveredIndex == index
                    let isCopied = copiedIndex == index

                    PieSlice(start: start, end: end, innerRatio: innerRatio)
                        .fill(sliceColor(hovered: isHovered, copied: isCopied))
                        .overlay(
                            PieSlice(start: start, end: end, innerRatio: innerRatio)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                        .contentShape(PieSlice(start: start, end: end, innerRatio: innerRatio))
                        .onHover { inside in
                            if inside {
                                hoveredIndex = index
                            } else if hoveredIndex == index {
                                hoveredIndex = nil
                            }
                        }
                        .onTapGesture { select(index) }
                        .scaleEffect(isHovered ? 1.03 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: hoveredIndex)

                    VStack(spacing: 2) {
                        if index < 9 {
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        Text(snippet.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(isHovered ? Color.white : Color.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: radius * 0.55)
                    }
                    .position(
                        x: geo.size.width / 2 + cos(mid.radians) * labelRadius,
                        y: geo.size.height / 2 + sin(mid.radians) * labelRadius
                    )
                    .allowsHitTesting(false)
                }

                centerCircle(radius: radius)
            }
        }
        .padding(6)
    }

    private func centerCircle(radius: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.97))
                .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))

            if let index = copiedIndex ?? hoveredIndex, snippets.indices.contains(index) {
                VStack(spacing: 4) {
                    if copiedIndex != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text("Kopiert!")
                            .font(.system(size: 12, weight: .semibold))
                    } else {
                        Text(snippets[index].title)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                        Text(snippets[index].text)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(8)
                .frame(maxWidth: radius * 2 * innerRatio - 24)
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "doc.on.doc")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("CopyWheel")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: radius * 2 * innerRatio - 8, height: radius * 2 * innerRatio - 8)
        .onTapGesture { onDismiss() }
    }

    private func sliceColor(hovered: Bool, copied: Bool) -> Color {
        if copied { return .green }
        if hovered { return .accentColor }
        return Color(nsColor: .windowBackgroundColor).opacity(0.92)
    }

    func select(_ index: Int) {
        guard snippets.indices.contains(index), copiedIndex == nil else { return }
        copiedIndex = index
        onSelect(snippets[index])
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
