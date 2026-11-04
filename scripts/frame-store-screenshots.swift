#!/usr/bin/env swift
// Frames the App Store screenshots: each raw shot from
// docs/release/screenshots/raw/ goes on a dark #121212 canvas of 1320 x 2868
// with its headline above it, in SF Rounded with the accent words in lime
// #D1FF00. The framed PNGs go to docs/release/screenshots/framed/.
//
// The headlines come from the "Zrzuty ekranu" table in
// docs/release/app-store-listing.md: one row per shot, `| 01-home | Wiesz,
// co<br>ćwiczyć *dziś* | … |`, where *stars* mark the accent words and
// `<br>` breaks the line.
//
// Usage (from the repository root):
//   xcrun swift scripts/frame-store-screenshots.swift [--contact-sheet <png>]
//
// --contact-sheet also writes every framed shot side by side into one PNG.

import AppKit
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Layout
let canvasSize = CGSize(width: 1320, height: 2868)
let background = CGColor(srgbRed: 0x12 / 255, green: 0x12 / 255, blue: 0x12 / 255, alpha: 1)
let accent = CGColor(srgbRed: 0xD1 / 255, green: 0xFF / 255, blue: 0x00 / 255, alpha: 1)
let headlineColor = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
let headlineSize: CGFloat = 112
let headlineWidth: CGFloat = 1140
/// The headline's band, measured from the top of the canvas.
let headlineBand = (top: CGFloat(110), bottom: CGFloat(520))
let shotScale: CGFloat = 0.78
let shotBottomMargin: CGFloat = 70
/// The device's display corners at the shot's scale.
let shotCornerRadius: CGFloat = 140
let maxHeadlineCharacters = 30

let raw = URL(fileURLWithPath: "docs/release/screenshots/raw")
let framed = URL(fileURLWithPath: "docs/release/screenshots/framed")
let listing = URL(fileURLWithPath: "docs/release/app-store-listing.md")

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("frame-store-screenshots: \(message)\n".utf8))
    exit(1)
}

// MARK: - Headlines
/// `(file name, headline with *accent* marks)` from the listing's table.
func headlines() -> [(name: String, headline: String)] {
    guard let text = try? String(contentsOf: listing, encoding: .utf8) else { fail("cannot read \(listing.path)") }
    let row = #/^\|\s*`?(\d\d-[a-z0-9-]+)`?\s*\|\s*(.+?)\s*\|/#
    var result: [(String, String)] = []
    for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
        if let match = line.firstMatch(of: row) {
            result.append((String(match.1), String(match.2)))
        }
    }
    if result.isEmpty { fail("no `| 01-name | headline |` rows in \(listing.path)") }
    return result
}

/// The headline without its marks, as the App Store reader sees it.
func plainText(_ headline: String) -> String {
    headline.replacingOccurrences(of: "*", with: "").replacingOccurrences(of: "<br>", with: " ")
}

/// The headline as attributed text: lime between stars, white elsewhere,
/// a line break at each `<br>`.
func attributed(_ headline: String) -> NSAttributedString {
    let base = NSFont.systemFont(ofSize: headlineSize, weight: .heavy)
    let rounded = base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: headlineSize) } ?? base
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineHeightMultiple = 0.95
    let result = NSMutableAttributedString()
    let lines = headline.replacingOccurrences(of: "<br>", with: "\n")
    for (index, part) in lines.split(separator: "*", omittingEmptySubsequences: false).enumerated() {
        result.append(NSAttributedString(string: String(part), attributes: [
            .font: rounded,
            .foregroundColor: index.isMultiple(of: 2) ? headlineColor : accent,
            .paragraphStyle: paragraph,
            .kern: -1.5
        ]))
    }
    return result
}

// MARK: - Images
func loadImage(_ url: URL) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fail("cannot read \(url.path)") }
    return image
}

func writePNG(_ image: CGImage, to url: URL) {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { fail("cannot write \(url.path)") }
    CGImageDestinationAddImage(destination, image, nil)
    if !CGImageDestinationFinalize(destination) { fail("cannot write \(url.path)") }
}

func makeContext(_ size: CGSize) -> CGContext {
    guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height),
                                  bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    else { fail("cannot create a bitmap") }
    return context
}

/// One framed shot. CoreGraphics counts y from the bottom.
func frame(_ shot: CGImage, headline: String) -> CGImage {
    let context = makeContext(canvasSize)
    context.setFillColor(background)
    context.fill(CGRect(origin: .zero, size: canvasSize))

    // The screenshot, centred, its bottom `shotBottomMargin` above the edge.
    let size = CGSize(width: CGFloat(shot.width) * shotScale, height: CGFloat(shot.height) * shotScale)
    let rect = CGRect(x: (canvasSize.width - size.width) / 2, y: shotBottomMargin, width: size.width, height: size.height)
    let outline = CGPath(roundedRect: rect, cornerWidth: shotCornerRadius, cornerHeight: shotCornerRadius, transform: nil)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -12), blur: 60,
                      color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.6))
    context.addPath(outline)
    context.setFillColor(background)
    context.fillPath()
    context.restoreGState()
    context.saveGState()
    context.addPath(outline)
    context.clip()
    context.interpolationQuality = .high
    context.draw(shot, in: rect)
    context.restoreGState()
    context.addPath(outline)
    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.12))
    context.setLineWidth(4)
    context.strokePath()

    // The headline, centred in its band.
    let text = attributed(headline)
    let setter = CTFramesetterCreateWithAttributedString(text)
    let fitted = CTFramesetterSuggestFrameSizeWithConstraints(
        setter, CFRange(), nil, CGSize(width: headlineWidth, height: .greatestFiniteMagnitude), nil)
    let bandHeight = headlineBand.bottom - headlineBand.top
    if fitted.height > bandHeight { fail("headline \"\(headline)\" needs more than its band") }
    let top = headlineBand.top + (bandHeight - fitted.height) / 2
    let textRect = CGRect(x: (canvasSize.width - headlineWidth) / 2, y: canvasSize.height - top - fitted.height,
                          width: headlineWidth, height: ceil(fitted.height))
    let textFrame = CTFramesetterCreateFrame(setter, CFRange(), CGPath(rect: textRect, transform: nil), nil)
    CTFrameDraw(textFrame, context)

    guard let image = context.makeImage() else { fail("cannot render \(headline)") }
    return image
}

/// Every framed shot in one row, scaled down, for a quick review.
func contactSheet(_ images: [CGImage]) -> CGImage {
    let scale: CGFloat = 0.25
    let gap: CGFloat = 40
    let tile = CGSize(width: canvasSize.width * scale, height: canvasSize.height * scale)
    let size = CGSize(width: gap + CGFloat(images.count) * (tile.width + gap), height: tile.height + 2 * gap)
    let context = makeContext(size)
    context.setFillColor(CGColor(srgbRed: 0.04, green: 0.04, blue: 0.04, alpha: 1))
    context.fill(CGRect(origin: .zero, size: size))
    context.interpolationQuality = .high
    for (index, image) in images.enumerated() {
        let x = gap + CGFloat(index) * (tile.width + gap)
        context.draw(image, in: CGRect(origin: CGPoint(x: x, y: gap), size: tile))
    }
    guard let image = context.makeImage() else { fail("cannot render the contact sheet") }
    return image
}

// MARK: - Main
var contactSheetURL: URL?
var arguments = CommandLine.arguments.dropFirst()
while let argument = arguments.popFirst() {
    switch argument {
    case "--contact-sheet":
        guard let path = arguments.popFirst() else { fail("--contact-sheet needs a path") }
        contactSheetURL = URL(fileURLWithPath: path)
    default:
        fail("unknown argument \(argument)")
    }
}

try? FileManager.default.createDirectory(at: framed, withIntermediateDirectories: true)
var rendered: [CGImage] = []
for (name, headline) in headlines() {
    let plain = plainText(headline)
    if plain.count > maxHeadlineCharacters {
        fail("\(name): \"\(plain)\" has \(plain.count) characters, at most \(maxHeadlineCharacters)")
    }
    let source = raw.appendingPathComponent("\(name).png")
    guard FileManager.default.fileExists(atPath: source.path) else {
        fail("\(source.path) is missing; run scripts/store-screenshots.sh first")
    }
    let image = frame(loadImage(source), headline: headline)
    writePNG(image, to: framed.appendingPathComponent("\(name).png"))
    rendered.append(image)
    print("Framed \(name): \(plain)")
}
if let contactSheetURL {
    writePNG(contactSheet(rendered), to: contactSheetURL)
    print("Contact sheet: \(contactSheetURL.path)")
}
