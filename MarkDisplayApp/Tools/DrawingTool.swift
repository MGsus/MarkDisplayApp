// DrawingTool.swift
// MarkDisplayApp
//
// Protocol that every annotation tool conforms to.
// Tools receive raw mouse events and produce/commit Strokes to the canvas.
//
// Adding a new tool: add a case to ToolType, create a class conforming to
// DrawingTool, and register it in AnnotationCanvasView.tools.

import AppKit

/// Identifies the kind of tool currently active.
enum ToolType: String, Codable, CaseIterable {
    case pen
    case highlighter
    case shape
    case eraser
}

/// Contract for all annotation tools.
protocol DrawingTool: AnyObject {

    var toolType: ToolType { get }

    /// Called when the user presses the mouse button.
    func mouseDown(at point: CGPoint, in view: AnnotationCanvasView)

    /// Called on each drag event; the tool may update `view.inProgressStroke`.
    func mouseDragged(to point: CGPoint, in view: AnnotationCanvasView)

    /// Called when the mouse button is released; the tool should commit the stroke.
    func mouseUp(at point: CGPoint, in view: AnnotationCanvasView)
}
