import Foundation
import TileCore
import TileMath

/// Renders one TeX formula to SVG markup. Reads the TeX from standard input and the
/// math font from the path in argv[1] (default "font.otf"). Used both as a host CLI
/// and as the WebAssembly entry point for the in-browser playground, where bundle
/// resources are unavailable so the font is supplied as bytes.
let fontPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "font.otf"

guard let fontData = FileManager.default.contents(atPath: fontPath) else {
    FileHandle.standardError.write(Data("cannot read font at \(fontPath)\n".utf8))
    exit(1)
}

let input = FileHandle.standardInput.readDataToEndOfFile()
let tex = String(data: input, encoding: .utf8) ?? ""

if let markup = TileKit.Math.svgMarkup(forTeX: tex, display: true, fontBytes: [UInt8](fontData)) {
    print(markup)
} else {
    print("<p class=\"td-math-error\">Could not parse that formula.</p>")
}
