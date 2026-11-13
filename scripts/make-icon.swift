// 六本豆 app icon, rendered as a 1024px vector image on macOS.
import AppKit
import CoreGraphics

guard CommandLine.arguments.count == 2 else { exit(64) }
let size = 1024
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
let graphics = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.current = graphics
let cg = graphics.cgContext
cg.setShouldAntialias(true)
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: a)
}
let rect = CGRect(x: 92, y: 92, width: 840, height: 840)
let base = CGPath(roundedRect: rect, cornerWidth: 188, cornerHeight: 188, transform: nil)
cg.saveGState()
cg.setShadow(offset: CGSize(width: 0, height: -12), blur: 30,
    color: NSColor.black.withAlphaComponent(0.22).cgColor)
cg.setFillColor(color(0.04, 0.22, 0.19).cgColor)
cg.addPath(base)
cg.fillPath()
cg.restoreGState()
cg.saveGState()
cg.addPath(base)
cg.clip()
let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
    colors: [color(0.14, 0.61, 0.43).cgColor, color(0.04, 0.27, 0.23).cgColor] as CFArray,
    locations: [0, 1])!
cg.drawLinearGradient(gradient, start: CGPoint(x: 260, y: 940),
    end: CGPoint(x: 790, y: 70), options: [])
// Six small seed marks frame the central 六 without reducing small-size legibility.
for index in 0..<6 {
    let angle = CGFloat(index) * .pi / 3 + .pi / 6
    let x = 512 + cos(angle) * 310
    let y = 555 + sin(angle) * 280
    cg.saveGState()
    cg.translateBy(x: x, y: y)
    cg.rotate(by: angle + .pi / 4)
    cg.setFillColor(color(0.97, 0.88, 0.61, 0.90).cgColor)
    cg.fillEllipse(in: CGRect(x: -19, y: -31, width: 38, height: 62))
    cg.setStrokeColor(color(0.07, 0.34, 0.27, 0.65).cgColor)
    cg.setLineWidth(3)
    cg.move(to: CGPoint(x: 0, y: -21))
    cg.addQuadCurve(to: CGPoint(x: 0, y: 21), control: CGPoint(x: 9, y: 0))
    cg.strokePath()
    cg.restoreGState()
}
func drawCentered(_ text: String, y: CGFloat, fontSize: CGFloat, weight: NSFont.Weight) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: weight),
        .foregroundColor: color(1, 0.98, 0.90)
    ]
    let string = text as NSString
    let measured = string.size(withAttributes: attributes)
    string.draw(at: CGPoint(x: (1024 - measured.width) / 2, y: y), withAttributes: attributes)
}
drawCentered("六", y: 335, fontSize: 390, weight: .semibold)
drawCentered("六本豆", y: 190, fontSize: 86, weight: .medium)
cg.restoreGState()
NSGraphicsContext.restoreGraphicsState()
let png = bitmap.representation(using: .png, properties: [:])!
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
