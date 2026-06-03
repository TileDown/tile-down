import MathTypeset
import TileCore

extension TileKit.Math {
    /// Converts a parsed `MathNode` tree into MathML Core markup. This is a pure
    /// tree walk: semantic MathML needs no layout box or font metrics, so the
    /// writer depends only on the parser's output. Text content is XML-escaped.
    struct MathMLWriter {
        /// The MathML for a node, without the enclosing `<math>` element.
        func mathML(
            _ node: MathNode,
        ) -> String {
            switch node {
            case let .sequence(nodes):
                row(nodes)
            case let .text(text):
                token(text)
            case let .symbol(display, _, _):
                "<mo>\(esc(display))</mo>"
            case let .fraction(numerator, denominator):
                "<mfrac>\(group(numerator))\(group(denominator))</mfrac>"
            case let .radical(radicand):
                "<msqrt>\(mathML(radicand))</msqrt>"
            case let .scripts(base, sub, sup):
                scripts(base: base, sub: sub, sup: sup)
            case let .accent(symbol, _, _, base):
                "<mover accent=\"true\">\(group(base))<mo>\(esc(symbol))</mo></mover>"
            case let .matrix(rows, open, close, leftAlign):
                matrix(rows: rows, open: open, close: close, leftAlign: leftAlign)
            case let .scaledDelimiter(symbol, _):
                "<mo>\(esc(symbol))</mo>"
            }
        }

        /// A sequence wrapped in `<mrow>` so it groups as a single unit.
        private func row(
            _ nodes: [MathNode],
        ) -> String {
            "<mrow>\(nodes.map(mathML).joined())</mrow>"
        }

        /// A child wrapped in `<mrow>` for contexts (fraction, scripts) where
        /// MathML expects exactly one argument element.
        private func group(
            _ node: MathNode,
        ) -> String {
            "<mrow>\(mathML(node))</mrow>"
        }

        /// A literal run classified into the right MathML token: numbers to
        /// `<mn>`, identifiers to `<mi>`, anything else to `<mtext>`.
        private func token(
            _ text: String,
        ) -> String {
            if !text.isEmpty, text.allSatisfy({ $0.isNumber || $0 == "." }) {
                return "<mn>\(esc(text))</mn>"
            }
            if !text.isEmpty, text.allSatisfy(\.isLetter) {
                return "<mi>\(esc(text))</mi>"
            }
            return "<mtext>\(esc(text))</mtext>"
        }

        private func scripts(
            base: MathNode,
            sub: MathNode?,
            sup: MathNode?,
        ) -> String {
            switch (sub, sup) {
            case let (sub?, sup?):
                "<msubsup>\(group(base))\(group(sub))\(group(sup))</msubsup>"
            case let (sub?, nil):
                "<msub>\(group(base))\(group(sub))</msub>"
            case let (nil, sup?):
                "<msup>\(group(base))\(group(sup))</msup>"
            case (nil, nil):
                mathML(base)
            }
        }

        private func matrix(
            rows: [[MathNode]],
            open: String,
            close: String,
            leftAlign: Bool,
        ) -> String {
            let body = rows.map { cells in
                "<mtr>\(cells.map { "<mtd>\(mathML($0))</mtd>" }.joined())</mtr>"
            }.joined()
            let align = leftAlign ? " columnalign=\"left\"" : ""
            let opening = open.isEmpty ? "" : "<mo>\(esc(open))</mo>"
            let closing = close.isEmpty ? "" : "<mo>\(esc(close))</mo>"
            return "<mrow>\(opening)<mtable\(align)>\(body)</mtable>\(closing)</mrow>"
        }

        private func esc(
            _ value: String,
        ) -> String {
            TileKit.HTML.escapeText(value)
        }
    }
}
