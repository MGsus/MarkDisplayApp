// main.swift
// Standalone check for StrokeHistory and eraser hit-testing (no XCTest needed).
// Run from the MarkDisplayApp/ directory:
//   swiftc -target arm64-apple-macos13.0 -sdk $(xcrun --show-sdk-path) \
//     $(find MarkDisplayApp -name '*.swift' ! -path '*/App/main.swift') \
//     Tests/main.swift -o /tmp/history-tests && /tmp/history-tests

import AppKit

func check(_ condition: Bool, _ message: String) {
    guard condition else { print("FAIL: \(message)"); exit(1) }
}

func line(_ a: CGPoint, _ b: CGPoint) -> Stroke {
    Stroke.make(toolType: .pen, points: [a, b], color: .red, lineWidth: 2)
}

// History: commit / undo / redo / clear
let h = StrokeHistory()
check(!h.canUndo && !h.canRedo, "starts empty")
h.commit(line(.zero, CGPoint(x: 10, y: 0)))
h.commit(line(.zero, CGPoint(x: 0, y: 10)))
check(h.past.count == 2, "two strokes committed")
h.undo()
check(h.past.count == 1 && h.canRedo, "undo moves a stroke to redo")
h.redo()
check(h.past.count == 2 && !h.canRedo, "redo restores it")
h.undo()
h.commit(line(.zero, CGPoint(x: 5, y: 5)))
check(!h.canRedo, "commit clears redo stack")
check(h.removeAll(where: { _ in true }) && h.past.isEmpty, "removeAll(where:) removes matches")
h.commit(line(.zero, CGPoint(x: 1, y: 1)))
h.clear()
check(h.past.isEmpty && !h.canUndo && !h.canRedo, "clear empties everything")

// Eraser hit-testing
let diagonal = line(CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 100))
check(diagonal.isHit(by: CGPoint(x: 50, y: 50), radius: 10), "hits on the line")
check(!diagonal.isHit(by: CGPoint(x: 90, y: 10), radius: 10), "misses empty bounding-box corner")

let rect = Stroke.make(toolType: .shape, shapeType: .rectangle,
                       points: [.zero, CGPoint(x: 100, y: 100)], color: .red, lineWidth: 2)
check(rect.isHit(by: CGPoint(x: 0, y: 50), radius: 10), "hits rectangle edge")
check(!rect.isHit(by: CGPoint(x: 50, y: 50), radius: 10), "misses rectangle interior")

// Regressions found in review
let circle = Stroke.make(toolType: .shape, shapeType: .circle,
                         points: [.zero, CGPoint(x: 100, y: 100)], color: .red, lineWidth: 2)
check(!circle.isHit(by: CGPoint(x: 3, y: 3), radius: 10), "circle misses bounding-box corner")
check(circle.isHit(by: CGPoint(x: 50, y: 0), radius: 10), "circle hits its outline")
check(!circle.isHit(by: CGPoint(x: 50, y: 50), radius: 10), "circle misses its centre")
check(!Stroke.make(toolType: .pen, points: [], color: .red, lineWidth: 2)
        .isHit(by: .zero, radius: 10), "empty stroke does not crash the eraser")
check(diagonal.bounds.contains(CGPoint(x: 100, y: 100)), "stroke bounds cover its points")

print("All checks passed")
