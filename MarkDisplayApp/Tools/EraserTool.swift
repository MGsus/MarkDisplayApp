// EraserTool.swift
// MarkDisplayApp
//
// Eraser tool — removes any committed stroke the pointer touches while dragging.
// Hit-testing is geometric (distance to the stroke's path / shape outline)
// rather than raw bounding boxes, so erasing near a diagonal line's empty
// bounding-box corner does not delete it.

import AppKit

class EraserTool: DrawingTool {

    let toolType: ToolType = .eraser

    /// Pointer radius used for hit-testing, in points.
    private let radius: CGFloat = 10

    func mouseDown(at point: CGPoint, in view: AnnotationCanvasView) {
        view.erase(at: point, radius: radius)
    }

    func mouseDragged(to point: CGPoint, in view: AnnotationCanvasView) {
        view.erase(at: point, radius: radius)
    }

    func mouseUp(at point: CGPoint, in view: AnnotationCanvasView) {}
}

// MARK: - Hit testing

extension Stroke {

    /// True if `point` is within `radius` of this stroke's visible geometry.
    func isHit(by point: CGPoint, radius: CGFloat) -> Bool {
        guard !points.isEmpty else { return false }
        let reach = radius + lineWidth / 2

        if toolType == .shape, points.count == 2, let shapeType {
            let a = points[0], b = points[1]
            switch shapeType {
            case .line, .arrow:
                return Stroke.distance(from: point, toSegment: a, b) <= reach
            case .rectangle:
                let rect = CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
                                  width: abs(a.x - b.x), height: abs(a.y - b.y))
                // Hit the outline band only, so the interior stays click-through.
                return rect.insetBy(dx: -reach, dy: -reach).contains(point)
                    && !rect.insetBy(dx: reach, dy: reach).contains(point)
            case .circle:
                // d == 1 on the ellipse outline; scaled back to points (approximate for thin ellipses).
                let rx = max(abs(a.x - b.x) / 2, 1), ry = max(abs(a.y - b.y) / 2, 1)
                let d = hypot((point.x - (a.x + b.x) / 2) / rx, (point.y - (a.y + b.y) / 2) / ry)
                return abs(d - 1) * min(rx, ry) <= reach
            }
        }

        if points.count == 1 {
            return hypot(point.x - points[0].x, point.y - points[0].y) <= reach
        }
        for (a, b) in zip(points, points.dropFirst())
        where Stroke.distance(from: point, toSegment: a, b) <= reach {
            return true
        }
        return false
    }

    private static func distance(from p: CGPoint, toSegment a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return hypot(p.x - a.x, p.y - a.y) }
        let t = max(0, min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared))
        return hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy))
    }
}
