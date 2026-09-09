// Erzeugt das App-Icon (1024er-Master-PNG) programmatisch:
// dunkler Squircle mit dem Rad-Motiv der App, ein Segment blau
// gehighlightet wie im Hover-Zustand.
// Aufruf: swift scripts/make-icon.swift <output.png>

import AppKit

let output = CommandLine.arguments[1]
let size = 1024

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Squircle-Grundfläche (Standard-Icon-Raster: 824pt zentriert in 1024)
let base = NSRect(x: 100, y: 100, width: 824, height: 824)
let squircle = NSBezierPath(roundedRect: base, xRadius: 185, yRadius: 185)
NSGradient(
    starting: NSColor(calibratedRed: 0.17, green: 0.18, blue: 0.22, alpha: 1),
    ending: NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.11, alpha: 1)
)!.draw(in: squircle, angle: -90)

// Rad: 5 Donut-Segmente mit Lücken, Segment oben "gehovert" (blau)
let cx: CGFloat = 512, cy: CGFloat = 512
let rOut: CGFloat = 305, rIn: CGFloat = 135
let count = 5
let segAngle = 360.0 / CGFloat(count)
let gap: CGFloat = 5

for i in 0..<count {
    let mid = 90 - CGFloat(i) * segAngle // y-up: 90° = oben
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
        NSColor(calibratedWhite: 0.87, alpha: 0.92).setFill()
        path.fill()
    }
}

// Mittelpunkt
NSColor(calibratedWhite: 0.87, alpha: 0.92).setFill()
NSBezierPath(ovalIn: NSRect(x: cx - 52, y: cy - 52, width: 104, height: 104)).fill()

NSGraphicsContext.current?.flushGraphics()
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("Icon: \(output)")
