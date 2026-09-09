// Erzeugt den DMG-Hintergrund (1200x800 px = 600x400 pt @2x):
// heller Verlauf, Titel, Pfeil von der App-Position zum Applications-Ordner.
// Die Icon-Positionen in der Makefile-dmg-Regel (150/185 und 450/185)
// müssen zu den hier gezeichneten Koordinaten passen.
// Aufruf: swift scripts/make-dmg-background.swift <output.png>

import AppKit

let output = CommandLine.arguments[1]
let w = 1200, h = 800
let scale: CGFloat = 2 // pt → px

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Hintergrund-Verlauf
NSGradient(
    starting: NSColor(calibratedRed: 0.96, green: 0.965, blue: 0.975, alpha: 1),
    ending: NSColor(calibratedRed: 0.885, green: 0.895, blue: 0.915, alpha: 1)
)!.draw(in: NSRect(x: 0, y: 0, width: w, height: h), angle: -90)

// Titel oben
func draw(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, centerXpt: CGFloat, topYpt: CGFloat) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size * scale, weight: weight),
        .foregroundColor: color,
    ]
    let str = NSAttributedString(string: text, attributes: attrs)
    let bounds = str.size()
    // topYpt ist der Abstand von oben in pt
    let y = CGFloat(h) - topYpt * scale - bounds.height
    str.draw(at: NSPoint(x: centerXpt * scale - bounds.width / 2, y: y))
}

draw("CopyWheel", size: 26, weight: .bold,
     color: NSColor(calibratedWhite: 0.22, alpha: 1), centerXpt: 300, topYpt: 40)
draw("Zum Installieren in den Applications-Ordner ziehen",
     size: 12, weight: .regular,
     color: NSColor(calibratedWhite: 0.45, alpha: 1), centerXpt: 300, topYpt: 78)

// Pfeil zwischen den Icon-Positionen (Icons: 128pt groß bei x=150 und x=450,
// y=185 von oben in create-dmg-Koordinaten)
let arrowYpt: CGFloat = 400 - 205 // y-up
let fromX: CGFloat = 235 * scale
let toX: CGFloat = 365 * scale
let y = arrowYpt * scale
let arrow = NSBezierPath()
arrow.lineWidth = 7 * scale
arrow.lineCapStyle = .round
arrow.move(to: NSPoint(x: fromX, y: y))
arrow.line(to: NSPoint(x: toX - 16 * scale, y: y))
NSColor(calibratedWhite: 0.62, alpha: 1).setStroke()
arrow.stroke()

let head = NSBezierPath()
head.move(to: NSPoint(x: toX, y: y))
head.line(to: NSPoint(x: toX - 22 * scale, y: y + 13 * scale))
head.line(to: NSPoint(x: toX - 22 * scale, y: y - 13 * scale))
head.close()
NSColor(calibratedWhite: 0.62, alpha: 1).setFill()
head.fill()

NSGraphicsContext.current?.flushGraphics()
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("Hintergrund: \(output)")
