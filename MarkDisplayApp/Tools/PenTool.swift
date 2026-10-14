// PenTool.swift
// MarkDisplayApp
//
// Freehand pen tool — accumulates CGPoints during drag and commits a Stroke on mouseUp.

import AppKit

class PenTool: DrawingTool {

    var toolType: ToolType { .pen }

    /// Visual parameters; HighlighterTool overrides these.
    var opacity: CGFloat { 1.0 }
    func width(from prefs: AppPreferences) -> CGFloat { prefs.strokeWidth }

    private var points: [CGPoint] = []

    func mouseDown(at point: CGPoint, in view: AnnotationCanvasView) {
        points = [point]
        view.inProgressStroke = makeStroke(in: view)
    }

    func mouseDragged(to point: CGPoint, in view: AnnotationCanvasView) {
        points.append(point)
        view.inProgressStroke = makeStroke(in: view)
    }

    func mouseUp(at point: CGPoint, in view: AnnotationCanvasView) {
        points.append(point)
        view.commit(makeStroke(in: view))
        points = []
    }

    private func makeStroke(in view: AnnotationCanvasView) -> Stroke {
        Stroke.make(
            toolType: toolType,
            points: points,
            color: view.currentColor,
            lineWidth: width(from: AppPreferences.shared),
            opacity: opacity
        )
    }
}
