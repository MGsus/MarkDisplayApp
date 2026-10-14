// StrokeHistory.swift
// MarkDisplayApp
//
// Owns the undo/redo stack using the classic two-array approach.
//   past   — strokes visible on the canvas (index 0 = oldest)
//   future — strokes available to redo (index 0 = most recently undone)

import Foundation

class StrokeHistory {

    private(set) var past: [Stroke] = []
    private var future: [Stroke] = []

    // MARK: - Mutations

    /// Commit a new stroke; clears the redo stack.
    func commit(_ stroke: Stroke) {
        past.append(stroke)
        future.removeAll()
    }

    /// Remove the most recently committed stroke and push it onto the redo stack.
    @discardableResult
    func undo() -> Stroke? {
        guard let last = past.popLast() else { return nil }
        future.append(last)
        return last
    }

    /// Re-apply the most recently undone stroke.
    @discardableResult
    func redo() -> Stroke? {
        guard let next = future.popLast() else { return nil }
        past.append(next)
        return next
    }

    /// Remove all strokes and clear the redo stack.
    func clear() {
        past.removeAll()
        future.removeAll()
    }

    /// Remove strokes matching the predicate (eraser / auto-erase).
    /// Returns true if anything was removed. Not undoable.
    @discardableResult
    func removeAll(where shouldRemove: (Stroke) -> Bool) -> Bool {
        let before = past.count
        past.removeAll(where: shouldRemove)
        return past.count != before
    }

    var canUndo: Bool { !past.isEmpty }
    var canRedo: Bool { !future.isEmpty }
}
