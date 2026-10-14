// HighlighterTool.swift
// MarkDisplayApp
//
// Highlighter — same behaviour as the pen but wide and semi-transparent.

import AppKit

class HighlighterTool: PenTool {

    override var opacity: CGFloat { 0.4 }
    override func width(from prefs: AppPreferences) -> CGFloat { max(20, prefs.strokeWidth * 4) }

    override var toolType: ToolType { .highlighter }
}
