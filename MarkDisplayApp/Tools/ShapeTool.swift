// ShapeTool.swift
// MarkDisplayApp
//
// Shape tool — draws arrow, line, rectangle, or circle from drag origin to current point.
// Shows a live preview during drag via AnnotationCanvasView.inProgressStroke.

import AppKit

enum ShapeType: String, Codable, CaseIterable {
    case arrow
    case line
    case rectangle
    case circle
}

class ShapeTool: DrawingTool {

    let toolType: ToolType = .shape
    var shapeType: ShapeType = .arrow

    private var origin: CGPoint = .zero

    func mouseDown(at point: CGPoint, in view: AnnotationCanvasView) {
        origin = point
        view.inProgressStroke = makeStroke(to: point, in: view)
    }

    func mouseDragged(to point: CGPoint, in view: AnnotationCanvasView) {
        view.inProgressStroke = makeStroke(to: point, in: view)
    }

    func mouseUp(at point: CGPoint, in view: AnnotationCanvasView) {
        // Ignore zero-size shapes (a simple click).
        if hypot(point.x - origin.x, point.y - origin.y) > 2 {
            view.commit(makeStroke(to: point, in: view))
        } else {
            view.inProgressStroke = nil
        }
    }

    private func makeStroke(to end: CGPoint, in view: AnnotationCanvasView) -> Stroke {
        Stroke.make(
            toolType: .shape,
            shapeType: shapeType,
            points: [origin, end],
            color: view.currentColor,
            lineWidth: AppPreferences.shared.strokeWidth
        )
    }
}
