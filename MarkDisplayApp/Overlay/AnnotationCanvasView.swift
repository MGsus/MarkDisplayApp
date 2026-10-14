// AnnotationCanvasView.swift
// MarkDisplayApp
//
// The single NSView that owns the stroke model and all Core Graphics drawing.
// wantsLayer stays false to avoid CALayer compositing artifacts on the
// transparent background.
//
// Architecture notes:
//   - New tools: conform to DrawingTool, add to `tools`.
//   - Cursor highlight / spotlight / zoom live in their own windows and never
//     touch this view.

import AppKit

class AnnotationCanvasView: NSView {

    // MARK: - State

    let history = StrokeHistory()

    /// Stroke currently being drawn (pen path or shape preview); rendered after committed strokes.
    var inProgressStroke: Stroke? {
        didSet { invalidateInProgress(from: oldValue) }
    }

    /// Called when the user presses Escape.
    var onExit: (() -> Void)?

    private let shapeTool = ShapeTool()
    private lazy var tools: [ToolType: DrawingTool] = [
        .pen: PenTool(),
        .highlighter: HighlighterTool(),
        .shape: shapeTool,
        .eraser: EraserTool()
    ]

    private(set) var activeToolType: ToolType = AppPreferences.shared.activeTool
    private var colorIndex = 0 { didSet { needsDisplay = true } }
    private var autoEraseTimer: Timer?

    private var activeTool: DrawingTool { tools[activeToolType]! }

    /// Currently selected favourite colour.
    var currentColor: NSColor {
        let colors = AppPreferences.shared.favoriteColors
        return NSColor(hex: colors[colorIndex % colors.count]) ?? .red
    }

    // MARK: - NSView overrides

    override var isOpaque: Bool { false }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    deinit { autoEraseTimer?.invalidate() }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        for stroke in history.past where stroke.bounds.intersects(dirtyRect) { render(stroke, in: ctx) }
        if let stroke = inProgressStroke { render(stroke, in: ctx) }
        drawToolIndicator()
    }

    /// Repaint only what changed: the newest pen segment, or old+new bounds for a shape preview.
    private func invalidateInProgress(from old: Stroke?) {
        guard let new = inProgressStroke else {
            if let old { setNeedsDisplay(old.bounds) }
            return
        }
        if new.toolType == .shape || old == nil {
            setNeedsDisplay(new.bounds.union(old?.bounds ?? .null))
        } else {
            let tail = new.points.suffix(2).reduce(CGRect.null) { $0.union(CGRect(origin: $1, size: .zero)) }
            setNeedsDisplay(tail.insetBy(dx: -(new.lineWidth + 16), dy: -(new.lineWidth + 16)))
        }
    }

    /// Small pill at top-centre showing the active tool (and shape) plus the current colour.
    private func drawToolIndicator() {
        var title = activeToolType.rawValue.capitalized
        if activeToolType == .shape { title += " · " + shapeTool.shapeType.rawValue.capitalized }
        if activeToolType != .eraser { title += " · \(Int(AppPreferences.shared.strokeWidth))px" }
        let text = NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: NSColor.white
        ])
        let size = text.size()
        let swatch: CGFloat = 14, pad: CGFloat = 12
        let showsColor = activeToolType != .eraser
        let width = size.width + pad * 2 + (showsColor ? swatch + 8 : 0)
        let pill = NSRect(x: bounds.midX - width / 2, y: bounds.maxY - 56, width: width, height: size.height + 14)

        NSColor.black.withAlphaComponent(0.7).setFill()
        NSBezierPath(roundedRect: pill, xRadius: pill.height / 2, yRadius: pill.height / 2).fill()

        var x = pill.minX + pad
        if showsColor {
            currentColor.setFill()
            NSBezierPath(ovalIn: NSRect(x: x, y: pill.midY - swatch / 2, width: swatch, height: swatch)).fill()
            x += swatch + 8
        }
        text.draw(at: NSPoint(x: x, y: pill.midY - size.height / 2))
    }

    private func render(_ stroke: Stroke, in ctx: CGContext) {
        guard let first = stroke.points.first else { return }
        ctx.saveGState()
        defer { ctx.restoreGState() }

        ctx.setStrokeColor(stroke.cgColor)
        ctx.setFillColor(stroke.cgColor)
        ctx.setLineWidth(stroke.lineWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        if stroke.toolType == .shape, stroke.points.count == 2, let shapeType = stroke.shapeType {
            renderShape(shapeType, from: first, to: stroke.points[1], in: ctx)
            return
        }

        if stroke.points.count == 1 {
            let r = stroke.lineWidth / 2
            ctx.fillEllipse(in: CGRect(x: first.x - r, y: first.y - r, width: stroke.lineWidth, height: stroke.lineWidth))
        } else {
            ctx.addLines(between: stroke.points)
            ctx.strokePath()
        }
    }

    private func renderShape(_ shape: ShapeType, from a: CGPoint, to b: CGPoint, in ctx: CGContext) {
        let rect = CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
        switch shape {
        case .line:
            ctx.addLines(between: [a, b])
        case .arrow:
            let angle = atan2(b.y - a.y, b.x - a.x)
            let head: CGFloat = 14
            let spread = CGFloat.pi / 7
            ctx.addLines(between: [a, b])
            ctx.move(to: b)
            ctx.addLine(to: CGPoint(x: b.x - head * cos(angle - spread), y: b.y - head * sin(angle - spread)))
            ctx.move(to: b)
            ctx.addLine(to: CGPoint(x: b.x - head * cos(angle + spread), y: b.y - head * sin(angle + spread)))
        case .rectangle:
            ctx.addRect(rect)
        case .circle:
            ctx.addEllipse(in: rect)
        }
        ctx.strokePath()
    }

    // MARK: - Mouse events

    private func location(of event: NSEvent) -> CGPoint {
        convert(event.locationInWindow, from: nil)
    }

    override func mouseDown(with event: NSEvent) {
        activeTool.mouseDown(at: location(of: event), in: self)
    }

    override func mouseDragged(with event: NSEvent) {
        activeTool.mouseDragged(to: location(of: event), in: self)
    }

    override func mouseUp(with event: NSEvent) {
        activeTool.mouseUp(at: location(of: event), in: self)
    }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""

        if flags == .command, key == "z" { undo(); return }
        if flags == [.command, .shift], key == "z" { redo(); return }

        guard flags.isEmpty else { super.keyDown(with: event); return }

        switch key {
        case "\u{1B}": onExit?()
        case "f": select(tool: .pen)
        case "h": select(tool: .highlighter)
        case "e": select(tool: .eraser)
        case "r": select(shape: .rectangle)
        case "c": select(shape: .circle)
        case "a": select(shape: .arrow)
        case "[": AppPreferences.shared.strokeWidth = max(1,  AppPreferences.shared.strokeWidth - 1); needsDisplay = true
        case "]": AppPreferences.shared.strokeWidth = min(9, AppPreferences.shared.strokeWidth + 1); needsDisplay = true
        case "1", "2", "3", "4", "5": colorIndex = Int(key)! - 1
        default: super.keyDown(with: event)
        }
    }

    // MARK: - Tool selection

    func select(tool: ToolType) {
        activeToolType = tool
        AppPreferences.shared.activeTool = tool
        inProgressStroke = nil
        needsDisplay = true  // indicator pill
    }

    /// Tab advances through every ToolType in declaration order.
    private func cycleTool() {
        let all = ToolType.allCases
        select(tool: all[(all.firstIndex(of: activeToolType)! + 1) % all.count])
    }

    func select(shape: ShapeType) {
        shapeTool.shapeType = shape
        select(tool: .shape)
    }

    /// Pressing S while already on the shape tool advances to the next shape.
    private func cycleShape() {
        if activeToolType == .shape {
            let all = ShapeType.allCases
            let next = (all.firstIndex(of: shapeTool.shapeType)! + 1) % all.count
            shapeTool.shapeType = all[next]
            needsDisplay = true
        } else {
            select(tool: .shape)
        }
    }

    // MARK: - Canvas operations

    func commit(_ stroke: Stroke) {
        history.commit(stroke)
        inProgressStroke = nil
        needsDisplay = true
    }

    func erase(at point: CGPoint, radius: CGFloat) {
        if history.removeAll(where: { $0.isHit(by: point, radius: radius) }) {
            needsDisplay = true
        }
    }

    func clear() {
        history.clear()
        inProgressStroke = nil
        needsDisplay = true
    }

    func undo() {
        history.undo()
        needsDisplay = true
    }

    func redo() {
        history.redo()
        needsDisplay = true
    }

    // MARK: - Auto-erase

    /// Runs only while the overlay is visible.
    func startAutoEraseTimer() {
        guard autoEraseTimer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            let prefs = AppPreferences.shared
            guard let self, prefs.autoEraseEnabled else { return }
            let cutoff = Date().addingTimeInterval(-prefs.autoEraseDelay)
            if self.history.removeAll(where: { $0.committedAt < cutoff }) {
                self.needsDisplay = true
            }
        }
        timer.tolerance = 0.5
        autoEraseTimer = timer
    }

    func stopAutoEraseTimer() {
        autoEraseTimer?.invalidate()
        autoEraseTimer = nil
    }
}
