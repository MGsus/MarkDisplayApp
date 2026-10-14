// MenuBarController.swift
// MarkDisplayApp
//
// Manages the NSStatusItem (menu bar icon) and its drop-down menu.
// OverlayWindowController is created lazily on the first toggle.

import AppKit

class MenuBarController: NSObject {

    // MARK: - Properties

    private let statusItem: NSStatusItem
    private var overlayController: OverlayWindowController?
    private var isAnnotating = false
    private var preferencesController: PreferencesWindowController?

    // Weak: the NSMenu retains its items; these are only for updating state
    private weak var toggleItem: NSMenuItem?
    private weak var clearItem: NSMenuItem?
    private weak var undoItem: NSMenuItem?
    private weak var redoItem: NSMenuItem?

    // MARK: - Init

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureStatusItem()
        configureMenu()
    }

    // MARK: - Setup

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(
            systemSymbolName: "pencil.and.outline",
            accessibilityDescription: "MarkDisplayApp"
        )
        button.image?.isTemplate = true
    }

    private func configureMenu() {
        let menu = NSMenu()

        // Toggle annotating
        let toggle = NSMenuItem(
            title: "Start Annotating",
            action: #selector(toggleAnnotation),
            keyEquivalent: ""
        )
        toggle.target = self
        menu.addItem(toggle)
        toggleItem = toggle

        menu.addItem(.separator())

        // Clear canvas
        let clear = NSMenuItem(
            title: "Clear Canvas",
            action: #selector(clearCanvas),
            keyEquivalent: ""
        )
        clear.target = self
        clear.isEnabled = false
        menu.addItem(clear)
        clearItem = clear

        // Undo
        let undo = NSMenuItem(
            title: "Undo",
            action: #selector(undoAction),
            keyEquivalent: ""
        )
        undo.target = self
        undo.isEnabled = false
        menu.addItem(undo)
        undoItem = undo

        // Redo
        let redo = NSMenuItem(
            title: "Redo",
            action: #selector(redoAction),
            keyEquivalent: ""
        )
        redo.target = self
        redo.isEnabled = false
        menu.addItem(redo)
        redoItem = redo

        menu.addItem(.separator())

        // Preferences
        let prefs = NSMenuItem(
            title: "Preferences…",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefs.keyEquivalentModifierMask = .command
        prefs.target = self
        menu.addItem(prefs)

        menu.addItem(.separator())

        // Quit
        let quit = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quit.keyEquivalentModifierMask = .command
        menu.addItem(quit)

        statusItem.menu = menu
    }

    // MARK: - Actions

    /// The overlay is the single source of truth; it reports back via `overlayDidChangeState`.
    @objc private func toggleAnnotation() {
        let overlay: OverlayWindowController
        if let existing = overlayController {
            overlay = existing
        } else {
            overlay = OverlayWindowController()
            overlay.delegate = self
            overlayController = overlay
        }
        if isAnnotating { overlay.deactivate() } else { overlay.activate() }
    }

    @objc private func clearCanvas() {
        overlayController?.canvasView.clear()
    }

    @objc private func undoAction() {
        overlayController?.canvasView.undo()
    }

    @objc private func redoAction() {
        overlayController?.canvasView.redo()
    }

    @objc private func openPreferences() {
        if preferencesController == nil {
            preferencesController = PreferencesWindowController()
        }
        NSApp.activate(ignoringOtherApps: true)
        preferencesController?.showWindow(nil)
        preferencesController?.window?.center()
    }

    // MARK: - Global shortcut entry points

    func toggleAnnotationFromShortcut() { toggleAnnotation() }
    func clearCanvasFromShortcut() { clearCanvas() }

    // MARK: - State sync

    private func syncMenuState() {
        toggleItem?.title = isAnnotating ? "Stop Annotating" : "Start Annotating"
        clearItem?.isEnabled = isAnnotating
        undoItem?.isEnabled = isAnnotating
        redoItem?.isEnabled = isAnnotating
    }
}

// MARK: - OverlayWindowControllerDelegate

extension MenuBarController: OverlayWindowControllerDelegate {
    func overlayDidChangeState(active: Bool) {
        isAnnotating = active
        syncMenuState()
    }
}
