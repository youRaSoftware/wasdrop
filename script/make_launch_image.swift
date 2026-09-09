// Launch-image helper: renders the app icon with iOS-style rounded corners
// (radius ≈ 22.37 % of the side, like the home-screen mask) on a transparent
// background at the requested pixel sizes.
//   swift make_launch_image.swift <icon1024.png> <outDir> <size>[,<size>...]
// Output: <outDir>/launch_<size>.png
import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count == 4 else {
    print("usage: make_launch_image.swift <icon.png> <outDir> <size,size,...>")
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

func savePNG(_ image: CGImage, to path: String) {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else { print("png fail"); exit(1) }
    try! data.write(to: URL(fileURLWithPath: path))
}

func rounded(_ icon: CGImage, size: Int) -> CGImage {
    let side = CGFloat(size)
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                        bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high
    let rect = CGRect(x: 0, y: 0, width: side, height: side)
    let path = CGPath(roundedRect: rect, cornerWidth: side * 0.2237, cornerHeight: side * 0.2237, transform: nil)
    ctx.addPath(path)
    ctx.clip()
    ctx.draw(icon, in: rect)
    return ctx.makeImage()!
}

let icon = loadImage(args[1])
let out = args[2]
for token in args[3].split(separator: ",") {
    guard let size = Int(token) else { print("bad size \(token)"); exit(1) }
    savePNG(rounded(icon, size: size), to: "\(out)/launch_\(size).png")
    print("launch_\(size).png")
}
