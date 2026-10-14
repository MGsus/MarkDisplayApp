// Stroke.swift
// MarkDisplayApp
//
// Value type representing a single committed annotation stroke.
// Made Codable for future persistence / export support.

import AppKit

struct Stroke: Codable {

    /// The kind of tool that produced this stroke.
    var toolType: ToolType

    /// For shape strokes — which shape; nil for freehand strokes.
    var shapeType: ShapeType?

    /// Ordered list of points that define the stroke path.
    /// - Freehand (pen/highlighter): all accumulated drag points.
    /// - Shape: [origin, endPoint] — two points are sufficient to reconstruct any shape.
    var points: [CGPoint]

    /// Stroke colour encoded as RGBA components for Codable conformance.
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    /// Line width in points.
    var lineWidth: CGFloat

    /// Opacity applied at render time (0–1). Highlighter uses < 1.
    var opacity: CGFloat

    /// Timestamp when the stroke was committed; used by auto-erase timer.
    var committedAt: Date

    /// Area this stroke can paint (points + line width + arrow head). Used to repaint and cull only what changed.
    var bounds: CGRect

    // MARK: - Convenience

    /// Render colour: one CGColor allocation instead of NSColor + bridging per frame.
    var cgColor: CGColor {
        CGColor(srgbRed: red, green: green, blue: blue, alpha: alpha * opacity)
    }

    // MARK: - Factory

    static func make(
        toolType: ToolType,
        shapeType: ShapeType? = nil,
        points: [CGPoint],
        color: NSColor,
        lineWidth: CGFloat,
        opacity: CGFloat = 1.0
    ) -> Stroke {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.usingColorSpace(.deviceRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
        let area = points.reduce(CGRect.null) { $0.union(CGRect(origin: $1, size: .zero)) }
        return Stroke(
            toolType: toolType,
            shapeType: shapeType,
            points: points,
            red: Double(r),
            green: Double(g),
            blue: Double(b),
            alpha: Double(a),
            lineWidth: lineWidth,
            opacity: opacity,
            committedAt: Date(),
            bounds: area.isNull ? .zero : area.insetBy(dx: -(lineWidth + 16), dy: -(lineWidth + 16))
        )
    }
}
