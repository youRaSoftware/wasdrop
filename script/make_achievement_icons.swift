// Иконки достижений Game Center: 512×512 PNG, кремовый круг с обводкой
// `#D9CFBB`, внутри спрайт фрукта (fruit.*) или крупная подпись Rubik
// Black (score / games / missions). Запуск — script/gen_achievement_icons.sh.
import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 3 else {
    fputs("usage: make_achievement_icons.swift <projectRoot> <outDir>\n", stderr)
    exit(1)
}
let root = args[1]
let outDir = args[2]
let size = 512
let cream = NSColor(red: 0xF7 / 255.0, green: 0xF2 / 255.0, blue: 0xE7 / 255.0, alpha: 1)
let wall = NSColor(red: 0xD9 / 255.0, green: 0xCF / 255.0, blue: 0xBB / 255.0, alpha: 1)
let ink = NSColor(red: 0x33 / 255.0, green: 0x29 / 255.0, blue: 0x1A / 255.0, alpha: 1)
let accent = NSColor(red: 0xF7 / 255.0, green: 0x6B / 255.0, blue: 0x15 / 255.0, alpha: 1)
let gold = NSColor(red: 0xEF / 255.0, green: 0xB0 / 255.0, blue: 0x08 / 255.0, alpha: 1)
let green = NSColor(red: 0x12 / 255.0, green: 0xA5 / 255.0, blue: 0x94 / 255.0, alpha: 1)

try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func registerFont(_ path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    CTFontManagerRegisterFontsForURL(url, .process, nil)
}
registerFont("\(root)/core/resources/fonts/Rubik-Black.ttf")

func canvas() -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    return rep
}

func draw(_ name: String, _ body: (CGContext) -> Void) {
    let rep = canvas()
    NSGraphicsContext.saveGraphicsState()
    let gctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gctx
    let ctx = gctx.cgContext
    let r = CGRect(x: 0, y: 0, width: size, height: size)
    // Фон: круг с обводкой (Apple скругляет сама, но круг читается лучше).
    ctx.setFillColor(wall.cgColor)
    ctx.fillEllipse(in: r.insetBy(dx: 8, dy: 8))
    ctx.setFillColor(cream.cgColor)
    ctx.fillEllipse(in: r.insetBy(dx: 26, dy: 26))
    body(ctx)
    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
    print("→ \(name).png")
}

func fruit(_ name: String, tier: Int) {
    draw(name) { ctx in
        let path = "\(root)/features/assets/images/fruits/t\(tier)_idle.png"
        guard let img = NSImage(contentsOfFile: path), let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fputs("no sprite \(path)\n", stderr); return
        }
        ctx.draw(cg, in: CGRect(x: 96, y: 96, width: 320, height: 320))
    }
}

func label(_ name: String, text: String, color: NSColor, sub: String? = nil) {
    draw(name) { _ in
        let big = NSFont(name: "Rubik-Black", size: sub == nil ? 190 : 170) ?? NSFont.boldSystemFont(ofSize: 180)
        let para = NSMutableParagraphStyle(); para.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [.font: big, .foregroundColor: color, .paragraphStyle: para]
        let str = NSAttributedString(string: text, attributes: attrs)
        let h = str.size().height
        let y = sub == nil ? (CGFloat(size) - h) / 2 : (CGFloat(size) - h) / 2 + 28
        str.draw(in: CGRect(x: 0, y: y, width: CGFloat(size), height: h))
        if let sub = sub {
            let small = NSFont(name: "Rubik-Black", size: 64) ?? NSFont.boldSystemFont(ofSize: 64)
            let sattrs: [NSAttributedString.Key: Any] = [.font: small, .foregroundColor: ink, .paragraphStyle: para]
            let s = NSAttributedString(string: sub, attributes: sattrs)
            s.draw(in: CGRect(x: 0, y: y - 80, width: CGFloat(size), height: 80))
        }
    }
}

fruit("fruit_lemon", tier: 4)
fruit("fruit_kiwi", tier: 6)
fruit("fruit_grape", tier: 8)
fruit("fruit_melon", tier: 10)
fruit("fruit_watermelon", tier: 11)
label("score_1k", text: "1K", color: accent)
label("score_10k", text: "10K", color: accent)
label("games_10", text: "10", color: green, sub: "GAMES")
label("games_100", text: "100", color: green, sub: "GAMES")
label("missions_25", text: "25", color: gold, sub: "★")
