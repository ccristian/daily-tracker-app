import AppKit
import Foundation

struct AssetGenerator {
  let projectRoot: URL

  private let iconFiles: [(String, CGFloat)] = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
  ]

  private let launchFiles: [(String, CGSize)] = [
    ("LaunchImage.png", CGSize(width: 168, height: 185)),
    ("LaunchImage@2x.png", CGSize(width: 336, height: 370)),
    ("LaunchImage@3x.png", CGSize(width: 504, height: 555)),
  ]

  func run() throws {
    let iconDirectory = projectRoot.appendingPathComponent("ios/Runner/Assets.xcassets/AppIcon.appiconset")
    let launchDirectory = projectRoot.appendingPathComponent("ios/Runner/Assets.xcassets/LaunchImage.imageset")

    for (filename, side) in iconFiles {
      let fileURL = iconDirectory.appendingPathComponent(filename)
      let bitmap = makeAppIcon(side: side)
      try writePNG(bitmap, to: fileURL)
    }

    for (filename, size) in launchFiles {
      let fileURL = launchDirectory.appendingPathComponent(filename)
      let bitmap = makeLaunchImage(size: size)
      try writePNG(bitmap, to: fileURL)
    }

    print("Generated \(iconFiles.count) iOS app icons and \(launchFiles.count) launch images.")
  }

  private func makeAppIcon(side: CGFloat) -> NSBitmapImageRep {
    renderBitmap(size: CGSize(width: side, height: side), transparent: false) { bounds in
      drawIconBackground(in: bounds)
      drawPlannerMark(in: bounds.insetBy(dx: side * 0.14, dy: side * 0.11), includeShadow: true)
    }
  }

  private func makeLaunchImage(size: CGSize) -> NSBitmapImageRep {
    renderBitmap(size: size, transparent: true) { bounds in
      let markWidth = min(size.width * 0.72, size.height * 0.64)
      let markHeight = markWidth * 1.08
      let markRect = NSRect(
        x: (size.width - markWidth) / 2,
        y: (size.height - markHeight) / 2,
        width: markWidth,
        height: markHeight
      )

      drawPlannerMark(in: markRect, includeShadow: true)
    }
  }

  private func renderBitmap(size: CGSize, transparent: Bool, draw: (NSRect) -> Void) -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: Int(size.width),
      pixelsHigh: Int(size.height),
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: 0,
      bitsPerPixel: 0
    ) else {
      fatalError("Unable to create bitmap representation.")
    }

    bitmap.size = size

    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
      fatalError("Unable to create graphics context for bitmap rendering.")
    }

    let bounds = NSRect(origin: .zero, size: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.shouldAntialias = true
    context.imageInterpolation = .high

    if transparent {
      NSColor.clear.setFill()
      bounds.fill()
    }

    draw(bounds)
    NSGraphicsContext.restoreGraphicsState()

    return bitmap
  }

  private func drawIconBackground(in rect: NSRect) {
    let gradient = NSGradient(colors: [
      color(0xF5C468),
      color(0xEA8D62),
      color(0xD96A55),
    ])!
    gradient.draw(in: rect, angle: -42)

    color(0xFFF7EC, alpha: 0.18).setFill()
    NSBezierPath(ovalIn: NSRect(
      x: -rect.width * 0.18,
      y: rect.height * 0.53,
      width: rect.width * 0.58,
      height: rect.height * 0.58
    )).fill()

    color(0x1F7A8C, alpha: 0.14).setFill()
    NSBezierPath(ovalIn: NSRect(
      x: rect.width * 0.60,
      y: -rect.height * 0.12,
      width: rect.width * 0.48,
      height: rect.height * 0.48
    )).fill()

    NSGraphicsContext.saveGraphicsState()
    let transform = NSAffineTransform()
    transform.translateX(by: rect.midX, yBy: rect.midY)
    transform.rotate(byDegrees: -18)
    transform.translateX(by: -rect.midX, yBy: -rect.midY)
    transform.concat()

    color(0xFFF7EC, alpha: 0.10).setFill()
    roundedRect(
      NSRect(
        x: rect.width * 0.06,
        y: rect.height * 0.70,
        width: rect.width * 0.88,
        height: rect.height * 0.10
      ),
      radius: rect.width * 0.05
    ).fill()
    NSGraphicsContext.restoreGraphicsState()
  }

  private func drawPlannerMark(in rect: NSRect, includeShadow: Bool) {
    let cardRect = NSRect(
      x: rect.minX + rect.width * 0.07,
      y: rect.minY + rect.height * 0.02,
      width: rect.width * 0.86,
      height: rect.height * 0.92
    )
    let cornerRadius = cardRect.width * 0.16

    if includeShadow {
      NSGraphicsContext.saveGraphicsState()
      let shadow = NSShadow()
      shadow.shadowBlurRadius = rect.width * 0.10
      shadow.shadowOffset = NSSize(width: 0, height: -rect.height * 0.03)
      shadow.shadowColor = color(0x7F4439, alpha: 0.24)
      shadow.set()
      color(0xFFF8EF).setFill()
      roundedRect(cardRect, radius: cornerRadius).fill()
      NSGraphicsContext.restoreGraphicsState()
    }

    color(0xFFF8EF).setFill()
    roundedRect(cardRect, radius: cornerRadius).fill()

    let bandHeight = cardRect.height * 0.24
    let bandRect = NSRect(
      x: cardRect.minX,
      y: cardRect.maxY - bandHeight,
      width: cardRect.width,
      height: bandHeight
    )
    color(0x1F7A8C).setFill()
    topRoundedRect(bandRect, radius: cornerRadius).fill()

    let binderRadius = cardRect.width * 0.045
    let binderY = bandRect.maxY - bandHeight * 0.42
    for offset in [0.24, 0.50, 0.76] {
      let binderRect = NSRect(
        x: cardRect.minX + cardRect.width * offset - binderRadius,
        y: binderY - binderRadius,
        width: binderRadius * 2,
        height: binderRadius * 2
      )
      color(0xF5C468).setFill()
      NSBezierPath(ovalIn: binderRect).fill()
    }

    let lineLeft = cardRect.minX + cardRect.width * 0.14
    let lineWidth = cardRect.width * 0.38
    let lineHeight = cardRect.height * 0.040
    let firstLineY = cardRect.minY + cardRect.height * 0.52
    let lineGap = cardRect.height * 0.12

    for index in 0..<3 {
      let lineRect = NSRect(
        x: lineLeft,
        y: firstLineY - CGFloat(index) * lineGap,
        width: lineWidth,
        height: lineHeight
      )
      color(0x3E5563, alpha: 0.18).setFill()
      roundedRect(lineRect, radius: lineHeight / 2).fill()
    }

    let badgeSize = cardRect.width * 0.40
    let badgeRect = NSRect(
      x: cardRect.maxX - badgeSize - cardRect.width * 0.14,
      y: cardRect.minY + cardRect.height * 0.16,
      width: badgeSize,
      height: badgeSize
    )

    if includeShadow {
      NSGraphicsContext.saveGraphicsState()
      let badgeShadow = NSShadow()
      badgeShadow.shadowBlurRadius = cardRect.width * 0.05
      badgeShadow.shadowOffset = NSSize(width: 0, height: -cardRect.height * 0.015)
      badgeShadow.shadowColor = color(0x0F4A57, alpha: 0.22)
      badgeShadow.set()
      color(0x1F7A8C).setFill()
      NSBezierPath(ovalIn: badgeRect).fill()
      NSGraphicsContext.restoreGraphicsState()
    }

    color(0x1F7A8C).setFill()
    NSBezierPath(ovalIn: badgeRect).fill()

    let accentSize = badgeRect.width * 0.22
    let accentRect = NSRect(
      x: badgeRect.maxX - accentSize * 0.72,
      y: badgeRect.maxY - accentSize * 0.58,
      width: accentSize,
      height: accentSize
    )
    color(0xF08D64).setFill()
    NSBezierPath(ovalIn: accentRect).fill()

    let check = NSBezierPath()
    check.lineCapStyle = .round
    check.lineJoinStyle = .round
    check.lineWidth = badgeRect.width * 0.14
    check.move(to: NSPoint(x: badgeRect.minX + badgeRect.width * 0.24, y: badgeRect.minY + badgeRect.height * 0.50))
    check.line(to: NSPoint(x: badgeRect.minX + badgeRect.width * 0.43, y: badgeRect.minY + badgeRect.height * 0.30))
    check.line(to: NSPoint(x: badgeRect.minX + badgeRect.width * 0.75, y: badgeRect.minY + badgeRect.height * 0.66))
    color(0xFFF8EF).setStroke()
    check.stroke()
  }

  private func roundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
  }

  private func topRoundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    let minX = rect.minX
    let maxX = rect.maxX
    let minY = rect.minY
    let maxY = rect.maxY

    path.move(to: NSPoint(x: minX, y: minY))
    path.line(to: NSPoint(x: minX, y: maxY - radius))
    path.curve(
      to: NSPoint(x: minX + radius, y: maxY),
      controlPoint1: NSPoint(x: minX, y: maxY - radius * 0.45),
      controlPoint2: NSPoint(x: minX + radius * 0.45, y: maxY)
    )
    path.line(to: NSPoint(x: maxX - radius, y: maxY))
    path.curve(
      to: NSPoint(x: maxX, y: maxY - radius),
      controlPoint1: NSPoint(x: maxX - radius * 0.45, y: maxY),
      controlPoint2: NSPoint(x: maxX, y: maxY - radius * 0.45)
    )
    path.line(to: NSPoint(x: maxX, y: minY))
    path.close()
    return path
  }

  private func color(_ hex: Int, alpha: CGFloat = 1.0) -> NSColor {
    NSColor(
      srgbRed: CGFloat((hex >> 16) & 0xFF) / 255.0,
      green: CGFloat((hex >> 8) & 0xFF) / 255.0,
      blue: CGFloat(hex & 0xFF) / 255.0,
      alpha: alpha
    )
  }

  private func writePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let pngData = bitmap.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
      throw NSError(domain: "AssetGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG data for \(url.lastPathComponent)."])
    }

    try pngData.write(to: url)
  }
}

let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let root = CommandLine.arguments.dropFirst().first.map { URL(fileURLWithPath: $0, relativeTo: currentDirectory).standardizedFileURL } ?? currentDirectory

do {
  try AssetGenerator(projectRoot: root).run()
} catch {
  fputs("Asset generation failed: \(error.localizedDescription)\n", stderr)
  exit(1)
}
