import Foundation
import MarkdownPDF
import TileCore
import TilePDF

/// Renders Markdown to a PDF document. Reads the Markdown from standard input and
/// writes the PDF to the path in argv[1] (default "out.pdf"). An optional argv[2] is
/// the path to an OpenType font with a `MATH` table (e.g. Latin Modern Math); when
/// present, it is embedded for all text roles and math is typeset with it, so `$...$`
/// formulas render. This is the host CLI and the WebAssembly entry point for the
/// in-browser PDF playground: a PDF is binary, so it is written to a (preopened)
/// output file the browser reads back, rather than piped to stdout. With no font,
/// Western text uses the built-in base-14 fonts and math falls back.
let arguments = CommandLine.arguments
let outputPath = arguments.count > 1 ? arguments[1] : "out.pdf"
let fontPath = arguments.count > 2 ? arguments[2] : nil
let markdown = String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""

/// Math on by default in fallback mode (base fonts, no embedded font needed, so it
/// is WASM-safe). If a TrueType (glyf) font with a MATH table is supplied, embed it
/// and use it for math. Note: MarkdownPDF cannot embed OpenType CFF fonts yet, so
/// Latin Modern Math (CFF) is not usable here; fallback rendering is used instead.
var options = PDFOptions(mathTypesetting: .enabled)
if let fontPath, let fontData = FileManager.default.contents(atPath: fontPath) {
    options = PDFOptions(
        embeddedFonts: .allRoles(.init(data: fontData)),
        mathTypesetting: .fontBacked,
    )
}

do {
    let data = try MarkdownPDFRenderer(options: options).render(markdown: TileKit.PDF.markdownForPDF(markdown))
    try data.write(to: URL(fileURLWithPath: outputPath))
} catch {
    FileHandle.standardError.write(Data("render failed: \(error)\n".utf8))
    exit(1)
}
