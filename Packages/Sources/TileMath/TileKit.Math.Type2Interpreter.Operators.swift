import MathTypeset
import TileCore

extension TileKit.Math.Type2Interpreter {
    /// Executes one operator and returns the index just past it (operators that
    /// carry trailing bytes, like the hint masks, consume them here).
    func execute(
        _ bytes: [UInt8],
        operator code: Int,
        at index: Int,
    ) throws -> Int {
        switch code {
        case 1, 3, 18, 23: // stem hints
            countStems()
            stack.removeAll()
        case 19, 20: // hintmask, cntrmask
            countStems()
            stack.removeAll()
            return index + 1 + (stemCount + 7) / 8
        case 21, 22, 4:
            move(code)
        case 5, 6, 7:
            lines(code)
        case 8, 24, 25, 26, 27, 30, 31:
            curves(code)
        case 10, 29:
            try callSubr(local: code == 10)
        case 14:
            endChar()
        case 12:
            flex(bytes[index + 1])
            return index + 2
        default:
            stack.removeAll()
        }
        return index + 1
    }

    private func move(_ code: Int) {
        switch code {
        case 22: moveTo(deltaX: lastAfterWidth, deltaY: 0) // hmoveto
        case 4: moveTo(deltaX: 0, deltaY: lastAfterWidth) // vmoveto
        default: moveTo(deltaX: penultimate, deltaY: last) // rmoveto
        }
    }

    private func lines(_ code: Int) {
        switch code {
        case 6: alternatingLines(startHorizontal: true) // hlineto
        case 7: alternatingLines(startHorizontal: false) // vlineto
        default: relativeLines() // rlineto
        }
    }

    private func curves(_ code: Int) {
        switch code {
        case 24: curveThenLine() // rcurveline
        case 25: lineThenCurve() // rlinecurve
        case 26: verticalCurves() // vvcurveto
        case 27: horizontalCurves() // hhcurveto
        case 30: alternatingCurves(startHorizontal: false) // vhcurveto
        case 31: alternatingCurves(startHorizontal: true) // hvcurveto
        default: relativeCurves() // rrcurveto
        }
    }

    // MARK: - Stems and width

    private func countStems() {
        takeWidth(evenArguments: true)
        stemCount += stack.count / 2
    }

    /// Drops the optional leading width argument the first stack-clearing operator
    /// may carry. Stem and mask operators take an even count, so an odd count
    /// means a leading width; move operators pass their expected argument count.
    private func takeWidth(
        evenArguments: Bool,
        expected: Int = 0,
    ) {
        guard !haveWidth else { return }
        let hasWidth = evenArguments ? stack.count % 2 == 1 : stack.count > expected
        if hasWidth, !stack.isEmpty {
            stack.removeFirst()
        }
        haveWidth = true
    }

    /// The last argument after removing a leading width (for single-delta moves).
    private var lastAfterWidth: Double {
        takeWidth(evenArguments: false, expected: 1)
        return stack.last ?? 0
    }

    private var last: Double {
        takeWidth(evenArguments: false, expected: 2)
        return stack.count >= 2 ? stack[stack.count - 1] : 0
    }

    private var penultimate: Double {
        stack.count >= 2 ? stack[stack.count - 2] : 0
    }

    // MARK: - Path construction

    func closeContour() {
        if isOpen {
            elements.append(.close)
            isOpen = false
        }
    }

    private func moveTo(deltaX: Double, deltaY: Double) {
        closeContour()
        penX += deltaX
        penY += deltaY
        elements.append(.move(.init(xPosition: penX, yPosition: penY)))
        isOpen = true
        stack.removeAll()
    }

    private func lineTo(deltaX: Double, deltaY: Double) {
        penX += deltaX
        penY += deltaY
        elements.append(.line(.init(xPosition: penX, yPosition: penY)))
    }

    /// Appends a cubic from six relative deltas: two control points then the end.
    private func curveTo(_ deltas: [Double]) {
        let control1 = TileKit.Math.Point(xPosition: penX + deltas[0], yPosition: penY + deltas[1])
        let control2 = TileKit.Math.Point(
            xPosition: control1.xPosition + deltas[2],
            yPosition: control1.yPosition + deltas[3],
        )
        let end = TileKit.Math.Point(
            xPosition: control2.xPosition + deltas[4],
            yPosition: control2.yPosition + deltas[5],
        )
        elements.append(.curve(control1: control1, control2: control2, end: end))
        penX = end.xPosition
        penY = end.yPosition
    }

    // MARK: - Lines

    private func relativeLines() {
        var index = 0
        while index + 2 <= stack.count {
            lineTo(deltaX: stack[index], deltaY: stack[index + 1])
            index += 2
        }
        stack.removeAll()
    }

    private func alternatingLines(startHorizontal: Bool) {
        var horizontal = startHorizontal
        for value in stack {
            if horizontal {
                lineTo(deltaX: value, deltaY: 0)
            } else {
                lineTo(deltaX: 0, deltaY: value)
            }
            horizontal.toggle()
        }
        stack.removeAll()
    }

    // MARK: - Curves

    private func relativeCurves() {
        var index = 0
        while index + 6 <= stack.count {
            curveTo(Array(stack[index ..< index + 6]))
            index += 6
        }
        stack.removeAll()
    }

    private func curveThenLine() {
        let lineStart = stack.count - 2
        var index = 0
        while index + 6 <= lineStart {
            curveTo(Array(stack[index ..< index + 6]))
            index += 6
        }
        lineTo(deltaX: stack[lineStart], deltaY: stack[lineStart + 1])
        stack.removeAll()
    }

    private func lineThenCurve() {
        let lineEnd = stack.count - 6
        var index = 0
        while index + 2 <= lineEnd {
            lineTo(deltaX: stack[index], deltaY: stack[index + 1])
            index += 2
        }
        curveTo(Array(stack[lineEnd ..< lineEnd + 6]))
        stack.removeAll()
    }

    private func horizontalCurves() {
        var index = 0
        var leadY = 0.0
        if stack.count % 4 == 1 {
            leadY = stack[0]
            index = 1
        }
        var first = true
        while index + 4 <= stack.count {
            curveTo([stack[index], first ? leadY : 0, stack[index + 1], stack[index + 2], stack[index + 3], 0])
            first = false
            index += 4
        }
        stack.removeAll()
    }

    private func verticalCurves() {
        var index = 0
        var leadX = 0.0
        if stack.count % 4 == 1 {
            leadX = stack[0]
            index = 1
        }
        var first = true
        while index + 4 <= stack.count {
            curveTo([first ? leadX : 0, stack[index], stack[index + 1], stack[index + 2], 0, stack[index + 3]])
            first = false
            index += 4
        }
        stack.removeAll()
    }

    private func alternatingCurves(startHorizontal: Bool) {
        var index = 0
        var horizontal = startHorizontal
        while stack.count - index >= 4 {
            let last5 = stack.count - index == 5
            if horizontal {
                let trailing = last5 ? stack[index + 4] : 0
                curveTo([stack[index], 0, stack[index + 1], stack[index + 2], trailing, stack[index + 3]])
            } else {
                let trailing = last5 ? stack[index + 4] : 0
                curveTo([0, stack[index], stack[index + 1], stack[index + 2], stack[index + 3], trailing])
            }
            index += last5 ? 5 : 4
            horizontal.toggle()
        }
        stack.removeAll()
    }

    // MARK: - Flex, subroutines, end

    /// The flex operators (escape 34-37) each describe two cubic curves with a
    /// compact argument layout. Coordinates the operator fixes (a flat axis or a
    /// return to the start) are emitted as zero deltas.
    private func flex(_ kind: UInt8) {
        let args = stack
        switch kind {
        case 34 where args.count >= 7: // hflex
            curveTo([args[0], 0, args[1], args[2], args[3], 0])
            curveTo([args[4], 0, args[5], -args[2], args[6], 0])
        case 36 where args.count >= 9: // hflex1
            curveTo([args[0], args[1], args[2], args[3], args[4], 0])
            curveTo([args[5], 0, args[6], args[7], args[8], -(args[1] + args[3] + args[7])])
        case 35 where args.count >= 12: // flex
            curveTo(Array(args[0 ..< 6]))
            curveTo(Array(args[6 ..< 12]))
        case 37 where args.count >= 11: // flex1
            flex1(args)
        default:
            break
        }
        stack.removeAll()
    }

    private func flex1(_ args: [Double]) {
        let totalX = args[0] + args[2] + args[4] + args[6] + args[8]
        let totalY = args[1] + args[3] + args[5] + args[7] + args[9]
        curveTo(Array(args[0 ..< 6]))
        if abs(totalX) > abs(totalY) {
            curveTo([args[6], args[7], args[8], args[9], args[10], -totalY])
        } else {
            curveTo([args[6], args[7], args[8], args[9], -totalX, args[10]])
        }
    }

    private func callSubr(local: Bool) throws {
        guard let entry = stack.popLast() else { return }
        let subrs = local ? cff.localSubrs : cff.globalSubrs
        let bias = local ? localBias : globalBias
        guard let object = subrs.object(Int(entry) + bias) else { return }
        try run(reader.bytes(at: object.offset, count: object.count))
    }

    private func endChar() {
        takeWidth(evenArguments: false, expected: stack.count == 1 || stack.count == 5 ? 0 : stack.count)
        closeContour()
        finished = true
    }
}
