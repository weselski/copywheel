// Erzeugt das GitHub-Social-Preview-Banner (2560x1280 = 1280x640 @2x):
// Rad-Motiv links, Titel + Tagline rechts.
// Aufruf: swift scripts/make-social-preview.swift <output.png>

import AppKit

let output = CommandLine.arguments[1]
let w = 2560, h = 1280

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Hintergrund
NSGradient(
    starting: NSColor(calibratedRed: 0.13, green: 0.14, blue: 0.17, alpha: 1),
    ending: NSColor(calibratedRed: 0.06, green: 0.07, blue: 0.09, alpha: 1)
)!.draw(in: NSRect(x: 0, y: 0, width: w, height: h), angle: -90)

// Rad links
let cx: CGFloat = 640, cy: CGFloat = 640
let rOut: CGFloat = 420, rIn: CGFloat = 185
let count = 5
let segAngle = 360.0 / CGFloat(count)
let gap: CGFloat = 4

for i in 0..<count {
    let mid = 90 - CGFloat(i) * segAngle
    let start = mid - segAngle / 2 + gap / 2
    let end = mid + segAngle / 2 - gap / 2
    let path = NSBezierPath()
    path.appendArc(withCenter: NSPoint(x: cx, y: cy), radius: rOut, startAngle: start, endAngle: end)
    path.appendArc(withCenter: NSPoint(x: cx, y: cy), radius: rIn, startAngle: end, endAngle: start, clockwise: true)
    path.close()
    if i == 0 {
        NSGradient(
            starting: NSColor(calibratedRed: 0.38, green: 0.58, blue: 1.0, alpha: 1),
            ending: NSColor(calibratedRed: 0.16, green: 0.38, blue: 0.95, alpha: 1)
        )!.draw(in: path, angle: -90)
    } else {
        NSColor(calibratedWhite: 0.85, alpha: 0.14).setFill()
        path.fill()
        NSColor(calibratedWhite: 0.9, alpha: 0.25).setStroke()
        path.lineWidth = 2
        path.stroke()
    }
}
NSColor(calibratedWhite: 0.85, alpha: 0.2).setFill()
NSBezierPath(ovalIn: NSRect(x: cx - 70, y: cy - 70, width: 140, height: 140)).fill()

// Text rechts
func draw(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, x: CGFloat, y: CGFloat) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
    ]
    NSAttributedString(string: text, attributes: attrs).draw(at: NSPoint(x: x, y: y))
}

draw("CopyWheel", size: 170, weight: .bold, color: .white, x: 1210, y: 700)
draw("Press a hotkey. Pick a snippet.", size: 72, weight: .regular,
     color: NSColor(calibratedWhite: 0.78, alpha: 1), x: 1215, y: 560)
draw("It's in your clipboard.", size: 72, weight: .regular,
     color: NSColor(calibratedWhite: 0.78, alpha: 1), x: 1215, y: 460)
draw("Native · Open Source · 1 MB", size: 54, weight: .medium,
     color: NSColor(calibratedRed: 0.45, green: 0.62, blue: 1.0, alpha: 1), x: 1215, y: 310)

NSGraphicsContext.current?.flushGraphics()
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("Banner: \(output)")
