// OverlayWindowController.swift
// MarkDisplayApp
//
// Manages the transparent full-screen annotation window.
//
// Architecture notes (future features plug in here):
//   - Cursor highlight: add a second NSWindow at a similar level,
//     managed by CursorHighlightController, toggled via a new menu item.
//   - Spotlight / zoom: add SpotlightWindowController at the same level.
//   - Neither requires changes to AnnotationCanvasView.

import AppKit

// MARK: - Delegate protocol

protocol OverlayWindowControllerDelegate: AnyObject {
    func overlayDidChangeState(active: Bool)
}

/// Borderless windows refuse key status by default; the canvas needs it for keyboard input.
private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

// MARK: - Controller

class OverlayWindowController: NSObject {

    // MARK: - Public state

    let canvasView: AnnotationCanvasView
    weak var delegate: OverlayWindowControllerDelegate?

    // MARK: - Private

    private let window: NSWindow
    private var isActive = false

    // MARK: - Init

    override init() {
        let frame = NSScreen.screens.first?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        canvasView = AnnotationCanvasView(frame: frame)
        window = OverlayWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        super.init()
        configureWindow()
        canvasView.onExit = { [weak self] in self?.deactivate() }
    }

    // MARK: - Window configuration

    private func configureWindow() {
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true  // pass-through until annotation is active
        window.isReleasedWhenClosed = false

        // Stay on all Spaces, above full-screen apps, out of window cycling.
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

        // Visible to screen-capture tools (Zoom, OBS, ...).
        window.sharingType = .readOnly

        window.contentView = canvasView
    }

    // MARK: - Activate / Deactivate

    /// Shows the overlay and routes mouse and keyboard events to the canvas.
    func activate() {
        guard !isActive else { return }
        isActive = true

        // Re-frame in case the display configuration changed.
        // Strokes are stored in view coordinates, so a size change would distort them: start clean.
        if let screenFrame = NSScreen.screens.first?.frame {
            if screenFrame.size != canvasView.frame.size { canvasView.clear() }
            window.setFrame(screenFrame, display: false)
            canvasView.frame = NSRect(origin: .zero, size: screenFrame.size)
        }

        window.ignoresMouseEvents = false
        canvasView.startAutoEraseTimer()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(canvasView)
        window.invalidateCursorRects(for: canvasView)

        delegate?.overlayDidChangeState(active: true)
    }

    /// Hides the overlay and passes all events through.
    func deactivate() {
        guard isActive else { return }
        isActive = false

        window.ignoresMouseEvents = true
        canvasView.stopAutoEraseTimer()
        window.orderOut(nil)

        delegate?.overlayDidChangeState(active: false)
    }
}
