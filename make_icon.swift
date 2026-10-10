import AppKit

// Renders the Battery Alert app icon (master 1024×1024 PNG).
// Dark notch-like squircle with a red low-battery glyph.

let S: CGFloat = 1024
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_master.png"

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let full = CGRect(x: 0, y: 0, width: S, height: S)

// Background squircle with a subtle top-to-bottom graphite gradient.
let corner = S * 0.2237
let bg = NSBezierPath(roundedRect: full, xRadius: corner, yRadius: corner)
bg.addClip()
let gradient = NSGradient(colors: [
    NSColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1),   // bottom
    NSColor(red: 0.19, green: 0.19, blue: 0.21, alpha: 1)    // top
])!
gradient.draw(in: full, angle: 90)

// Soft top highlight to echo the pill's specular edge.
let highlight = NSGradient(colors: [
    NSColor(white: 1, alpha: 0.10),
    NSColor(white: 1, alpha: 0.0)
])!
highlight.draw(in: CGRect(x: 0, y: S * 0.62, width: S, height: S * 0.38), angle: -90)

// --- Battery glyph, centered ---
let bodyW: CGFloat = 540, bodyH: CGFloat = 286
let bodyX = (S - bodyW) / 2 - 14   // shift left to leave room for terminal
let bodyY = (S - bodyH) / 2
let bodyRect = CGRect(x: bodyX, y: bodyY, width: bodyW, height: bodyH)
let bodyRadius: CGFloat = 70

// Outline (white, rounded).
let outline = NSBezierPath(roundedRect: bodyRect, xRadius: bodyRadius, yRadius: bodyRadius)
outline.lineWidth = 40
NSColor.white.setStroke()
outline.stroke()

// Terminal nub on the right.
let nub = NSBezierPath(roundedRect:
    CGRect(x: bodyRect.maxX + 26, y: S / 2 - 62, width: 50, height: 124),
    xRadius: 24, yRadius: 24)
NSColor.white.setFill()
nub.fill()

// Low-charge red fill inside, left-aligned.
let inset: CGFloat = 48
let fillW: CGFloat = 132
let fill = NSBezierPath(roundedRect:
    CGRect(x: bodyRect.minX + inset, y: bodyRect.minY + inset,
           width: fillW, height: bodyRect.height - inset * 2),
    xRadius: 34, yRadius: 34)
NSColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1).setFill()
fill.fill()

NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else {
    fputs("failed to encode PNG\n", stderr); exit(1)
}
try! data.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
