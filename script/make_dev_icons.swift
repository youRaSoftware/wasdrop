// Icon helper: samples the background colour of the app icon and renders
// "DEV"-badged variants of the iOS icon and the Android adaptive foreground.
//   swift icon_tool.swift <icon1024.png> <foreground1024.png> <outDir>
import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count == 4 else {
    print("usage: icon_tool.swift <icon.png> <foreground.png> <outDir>")
    exit(1)
}

func loadImage(_ path: String) -> CGImage {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        print("cannot load \(path)"); exit(1)
    }
    return image
}

func pixel(_ image: CGImage, x: Int, y: Int) -> (Int, Int, Int) {
    let ctx = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(image, in: CGRect(x: -x, y: -(image.height - 1 - y), width: image.width, height: image.height))
    let p = ctx.data!.assumingMemoryBound(to: UInt8.self)
    return (Int(p[0]), Int(p[1]), Int(p[2]))
}

func hex(_ c: (Int, Int, Int)) -> String { String(format: "#%02X%02X%02X", c.0, c.1, c.2) }

func savePNG(_ image: CGImage, to path: String) {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else { print("png fail"); exit(1) }
    try! data.write(to: URL(fileURLWithPath: path))
}

/// Draws `base` and a red band with white "DEV" text. `bandY0/bandY1` are
/// fractions of the height measured from the top.
func badge(_ base: CGImage, bandY0: CGFloat, bandY1: CGFloat, fontScale: CGFloat) -> CGImage {
    let size = CGFloat(base.width)
    let ctx = CGContext(data: nil, width: base.width, height: base.height, bitsPerComponent: 8,
                        bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(base, in: CGRect(x: 0, y: 0, width: size, height: size))

    // CoreGraphics is y-up: convert "from top" fractions.
    let top = size * (1 - bandY0)
    let bottom = size * (1 - bandY1)
    let band = CGRect(x: 0, y: bottom, width: size, height: top - bottom)
    ctx.setFillColor(CGColor(srgbRed: 0xE5 / 255, green: 0x48 / 255, blue: 0x4D / 255, alpha: 0.96))
    ctx.fill(band)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    let font = NSFont.systemFont(ofSize: size * fontScale, weight: .black)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white, .kern: size * 0.01]
    let text = NSAttributedString(string: "DEV", attributes: attrs)
    let textSize = text.size()
    text.draw(at: CGPoint(x: (size - textSize.width) / 2, y: band.midY - textSize.height / 2))
    NSGraphicsContext.restoreGraphicsState()
    return ctx.makeImage()!
}

let icon = loadImage(args[1])
let foreground = loadImage(args[2])
let out = args[3]

let corner = pixel(icon, x: 12, y: 12)
let bottom = pixel(icon, x: 12, y: icon.height - 12)
print("bg_top=\(hex(corner)) bg_bottom=\(hex(bottom))")

savePNG(badge(icon, bandY0: 0.74, bandY1: 0.93, fontScale: 0.15), to: out + "/icon_dev_1024.png")
// Adaptive foreground: keep the band inside the 66 % safe zone (17 %…83 %).
savePNG(badge(foreground, bandY0: 0.64, bandY1: 0.80, fontScale: 0.125), to: out + "/foreground_dev_1024.png")
print("done")
