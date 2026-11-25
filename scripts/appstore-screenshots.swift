import AppKit

// Composes the five 2880×1800 Mac App Store screenshots from captures of the app.
// usage: appstore-screenshots <fr|en> <capdir> <marksdir> <icon.png> <outdir>
// App Review rules: no price or "free" wording, no Apple logo, no Apple product names used as branding.
let a = CommandLine.arguments
let fr = a[1] == "fr"
let cap = a[2], marks = a[3], iconPath = a[4], out = a[5]
let W: CGFloat = 2880, H: CGFloat = 1800

func img(_ p: String) -> NSImage { NSImage(contentsOfFile: p)! }
func t(_ f: String, _ e: String) -> String { fr ? f : e }
let violet = NSColor(srgbRed: 0.66, green: 0.55, blue: 1.0, alpha: 1)
let teal = NSColor(srgbRed: 0.35, green: 0.85, blue: 0.75, alpha: 1)

func font(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    NSFont(name: weight == .heavy ? "SFProDisplay-Heavy" : "SFProDisplay-Semibold", size: size) ?? .systemFont(ofSize: size, weight: weight)
}

func drawText(_ s: String, _ f: NSFont, _ color: NSColor, at p: CGPoint, kern: CGFloat = 0) -> CGSize {
    let attr = NSAttributedString(string: s, attributes: [.font: f, .foregroundColor: color, .kern: kern])
    attr.draw(at: p)
    return attr.size()
}

func gradientText(_ s: String, _ f: NSFont, at p: CGPoint, _ ctx: CGContext) {
    let attr = NSAttributedString(string: s, attributes: [.font: f, .kern: -4])
    let line = CTLineCreateWithAttributedString(attr)
    let size = attr.size()
    ctx.saveGState()
    ctx.textPosition = CGPoint(x: p.x, y: p.y - f.descender)
    ctx.setTextDrawingMode(.clip)
    CTLineDraw(line, ctx)
    let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [violet.cgColor, NSColor(srgbRed: 0.75, green: 0.7, blue: 1, alpha: 1).cgColor, teal.cgColor] as CFArray, locations: [0, 0.5, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: p.x, y: 0), end: CGPoint(x: p.x + size.width, y: 0), options: [])
    ctx.restoreGState()
}

func shadowed(_ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let sh = NSShadow(); sh.shadowColor = NSColor.black.withAlphaComponent(0.55); sh.shadowBlurRadius = 60; sh.shadowOffset = NSSize(width: 0, height: -24)
    sh.set(); draw()
    NSGraphicsContext.restoreGraphicsState()
}

@discardableResult
func place(_ i: NSImage, x: CGFloat, y: CGFloat, height h: CGFloat) -> CGFloat {
    let w = i.size.width * h / i.size.height
    shadowed { i.draw(in: NSRect(x: x, y: y, width: w, height: h)) }
    return w
}
func width(_ i: NSImage, height h: CGFloat) -> CGFloat { i.size.width * h / i.size.height }

func tintedSymbol(_ name: String, size: CGFloat, color: NSColor) -> NSImage? {
    guard let s = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(.init(pointSize: size, weight: .semibold)) else { return nil }
    return NSImage(size: s.size, flipped: false) { r in s.draw(in: r); color.set(); r.fill(using: .sourceAtop); return true }
}

func slide(_ name: String, eyebrow: String, line1: String, line2: String, pill: String, content: (CGContext) -> Void) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H), bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: W, height: H)
    let nctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = nctx
    let ctx = nctx.cgContext
    let cs = CGColorSpaceCreateDeviceRGB()
    ctx.drawLinearGradient(CGGradient(colorsSpace: cs, colors: [NSColor(srgbRed: 0.03, green: 0.03, blue: 0.09, alpha: 1).cgColor, NSColor(srgbRed: 0.07, green: 0.05, blue: 0.16, alpha: 1).cgColor] as CFArray, locations: [0, 1])!,
                           start: .zero, end: CGPoint(x: 0, y: H), options: [])
    func glow(_ c: NSColor, _ p: CGPoint, _ r: CGFloat) {
        ctx.drawRadialGradient(CGGradient(colorsSpace: cs, colors: [c.cgColor, c.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!,
                               startCenter: p, startRadius: 0, endCenter: p, endRadius: r, options: [])
    }
    glow(NSColor(srgbRed: 0.49, green: 0.30, blue: 0.95, alpha: 0.55), CGPoint(x: W * 0.92, y: H * 1.02), 1500)
    glow(NSColor(srgbRed: 0.10, green: 0.70, blue: 0.55, alpha: 0.28), CGPoint(x: -100, y: 120), 1200)

    img(iconPath).draw(in: NSRect(x: 160, y: H - 290, width: 130, height: 130))
    _ = drawText("Menulens", font(66, .semibold), .white, at: CGPoint(x: 320, y: H - 260))
    let pf = font(42, .semibold)
    let ps = (pill as NSString).size(withAttributes: [.font: pf])
    let pr = NSRect(x: W - 160 - ps.width - 120, y: H - 270, width: ps.width + 120, height: 90)
    NSColor.white.withAlphaComponent(0.08).setFill(); NSBezierPath(roundedRect: pr, xRadius: 45, yRadius: 45).fill()
    NSColor.white.withAlphaComponent(0.14).setStroke(); let pb = NSBezierPath(roundedRect: pr.insetBy(dx: 1, dy: 1), xRadius: 44, yRadius: 44); pb.lineWidth = 2; pb.stroke()
    NSColor(srgbRed: 0.3, green: 0.85, blue: 0.6, alpha: 1).setFill(); NSBezierPath(ovalIn: NSRect(x: pr.minX + 40, y: pr.midY - 10, width: 20, height: 20)).fill()
    _ = drawText(pill, pf, .white, at: CGPoint(x: pr.minX + 80, y: pr.midY - ps.height / 2))

    _ = drawText(eyebrow.uppercased(), font(44, .semibold), violet, at: CGPoint(x: 160, y: H - 470), kern: 7)
    let hf = font(150, .heavy)
    _ = drawText(line1, hf, .white, at: CGPoint(x: 152, y: H - 680), kern: -4)
    gradientText(line2, hf, at: CGPoint(x: 152, y: H - 860), ctx)

    content(ctx)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name).png"))
}

let main = img("\(cap)/main.png"), battery = img("\(cap)/battery.png"), memory = img("\(cap)/memory.png")
let disk = img("\(cap)/disk.png"), vpn = img("\(cap)/vpn.png"), settings = img("\(cap)/settings.png")
let m = { (n: String) in img("\(marks)/\(n).png") }

// 1. The mark in a menu bar, the popover hanging below it.
slide(fr ? "1-Une-seule-icone" : "1-One-Icon", eyebrow: t("Barre des menus", "Menu bar"), line1: t("Toute votre barre des menus.", "Your whole menu bar."),
      line2: t("En une seule icône.", "In one single icon."), pill: t("Sans pistage", "No tracking")) { _ in
    let barY: CGFloat = 610
    let ph: CGFloat = 1240
    let pw = width(main, height: ph)
    let px = W - 380 - pw
    let mark = m("default")
    let ms: CGFloat = 200
    let markX = px + pw / 2 - ms / 2
    let clockFont = font(54, .semibold)
    let clock = t("Jeu. 12 nov.  9:41", "Thu Nov 12  9:41 AM")
    let cs = (clock as NSString).size(withAttributes: [.font: clockFont])
    let bar = NSRect(x: 1040, y: barY + 30, width: markX + ms + 40 + cs.width + 70 - 1040, height: 120)
    NSColor.white.withAlphaComponent(0.07).setFill(); NSBezierPath(roundedRect: bar, xRadius: 36, yRadius: 36).fill()
    _ = drawText(clock, clockFont, NSColor.white.withAlphaComponent(0.85), at: CGPoint(x: markX + ms + 40, y: bar.midY - cs.height / 2))
    mark.draw(in: NSRect(x: markX, y: bar.midY - ms / 2 + 4, width: ms, height: ms))
    for (i, sym) in ["wifi", "battery.75percent", "speaker.wave.2.fill", "lock.shield"].enumerated() {
        if let s = tintedSymbol(sym, size: 54, color: NSColor.white.withAlphaComponent(0.22)) {
            s.draw(at: CGPoint(x: bar.minX + 70 + CGFloat(i) * 130, y: bar.midY - s.size.height / 2), from: .zero, operation: .sourceOver, fraction: 1)
        }
    }
    _ = drawText(t("Avant", "Before"), font(34, .semibold), NSColor.white.withAlphaComponent(0.35), at: CGPoint(x: bar.minX + 70, y: bar.minY - 70))
    NSColor.white.withAlphaComponent(0.35).setStroke()
    let sl = NSBezierPath(); sl.move(to: CGPoint(x: bar.minX + 50, y: bar.midY)); sl.line(to: CGPoint(x: bar.minX + 600, y: bar.midY)); sl.lineWidth = 5; sl.stroke()
    place(main, x: px, y: barY + 30 - ph + 8, height: ph)
}

// 2. Detail pages.
slide(fr ? "2-Chaque-detail" : "2-Every-Detail", eyebrow: t("D'un coup d'œil", "At a glance"), line1: t("Chaque détail,", "Every detail,"),
      line2: t("à un clic.", "one click away."), pill: t("9 mesures", "9 metrics")) { _ in
    let h: CGFloat = 800
    let imgs = [battery, memory, disk]
    let hs: [CGFloat] = [h, h * memory.size.height / battery.size.height, h * disk.size.height / battery.size.height]
    let ws = zip(imgs, hs).map { width($0, height: $1) }
    let gap: CGFloat = 70
    var x = (W - ws.reduce(0, +) - gap * 2) / 2
    for (i, im) in imgs.enumerated() { place(im, x: x, y: 850 - hs[i], height: hs[i]); x += ws[i] + gap }
}

// 3. Customization.
slide(fr ? "3-Personnalisez" : "3-Make-It-Yours", eyebrow: t("Personnalisation", "Customization"), line1: t("Vos couleurs.", "Your colors."),
      line2: t("Vos informations.", "Your metrics."), pill: t("12 palettes", "12 palettes")) { _ in
    let sh: CGFloat = 1360
    place(settings, x: W - 220 - width(settings, height: sh), y: 90, height: sh)
    let names = ["default", "aurora-grad", "ocean-seg", "charging", "cpu42", "low10"]
    let s: CGFloat = 300, gx: CGFloat = 60, gy: CGFloat = 50
    for (i, n) in names.enumerated() {
        let r = NSRect(x: 160 + CGFloat(i % 3) * (s + gx), y: 560 - CGFloat(i / 3) * (s + gy), width: s, height: s)
        NSColor.white.withAlphaComponent(0.06).setFill(); NSBezierPath(roundedRect: r, xRadius: 60, yRadius: 60).fill()
        m(n).draw(in: r.insetBy(dx: 40, dy: 40))
    }
}

// 4. Connections.
slide(fr ? "4-Connexions" : "4-Connections", eyebrow: t("Connexions", "Connections"), line1: "Wi-Fi, Bluetooth, VPN.",
      line2: t("Tout est là.", "All in one place."), pill: t("En un clic", "One click")) { _ in
    let vh: CGFloat = 700
    place(vpn, x: W - 220 - width(vpn, height: vh), y: 120, height: vh)
    let ex = m("expanded")
    let ew: CGFloat = 1250
    let eh = ex.size.height * ew / ex.size.width
    let er = NSRect(x: 160, y: 520, width: ew + 120, height: eh + 100)
    NSColor.white.withAlphaComponent(0.07).setFill(); NSBezierPath(roundedRect: er, xRadius: 50, yRadius: 50).fill()
    ex.draw(in: NSRect(x: er.minX + 60, y: er.minY + 50, width: ew, height: eh))
    _ = drawText(t("Au survol, l'icône se déplie.", "Hover, and the icon unfolds."), font(52, .semibold), NSColor.white.withAlphaComponent(0.8), at: CGPoint(x: 170, y: 400))
    _ = drawText(t("Connectez vos VPN et appareils en un clic.", "Connect VPNs and devices in one click."), font(52, .semibold), NSColor.white.withAlphaComponent(0.55), at: CGPoint(x: 170, y: 320))
}

// 5. Privacy.
slide(fr ? "5-Local-et-prive" : "5-Local-And-Private", eyebrow: t("Local et privé", "Local & private"), line1: t("Aucune donnée collectée.", "No data collected."),
      line2: t("Tout reste chez vous.", "Everything stays local."), pill: t("Hors ligne", "Offline")) { _ in
    let items: [(String, String)] = [
        ("hand.raised.fill", t("Aucune requête réseau, aucun pistage, aucune pub", "No network requests, no tracking, no ads")),
        ("lock.fill", t("Tout est lu localement, via les API du système", "Everything is read locally, through system APIs")),
        ("leaf.fill", t("Seules les mesures affichées sont relevées", "Only the metrics you can see are sampled")),
        ("person.fill.xmark", t("Aucun compte à créer", "No account needed"))
    ]
    for (i, (sym, text)) in items.enumerated() {
        let y = 760 - CGFloat(i) * 160
        let r = NSRect(x: 160, y: y - 20, width: 110, height: 110)
        NSColor.white.withAlphaComponent(0.08).setFill(); NSBezierPath(roundedRect: r, xRadius: 30, yRadius: 30).fill()
        if let s = tintedSymbol(sym, size: 52, color: i % 2 == 0 ? violet : teal) {
            s.draw(at: CGPoint(x: r.midX - s.size.width / 2, y: r.midY - s.size.height / 2), from: .zero, operation: .sourceOver, fraction: 1)
        }
        _ = drawText(text, font(60, .semibold), .white, at: CGPoint(x: 320, y: y + 4))
    }
    shadowed { img(iconPath).draw(in: NSRect(x: W - 220 - 760, y: 180, width: 760, height: 760)) }
}
print("ok")
