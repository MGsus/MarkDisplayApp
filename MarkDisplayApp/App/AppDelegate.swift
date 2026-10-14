// AppDelegate.swift
// MarkDisplayApp
//
// Application entry-point delegate. Owns the top-level controllers.

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var menuBarController: MenuBarController?
    private var shortcutManager: ShortcutManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Global key monitors silently receive nothing without Input Monitoring access.
        if !CGPreflightListenEventAccess() { CGRequestListenEventAccess() }

        menuBarController = MenuBarController()

        let mc = menuBarController!
        let shortcuts = ShortcutManager()
        shortcuts.registerDefaults(
            toggleAnnotation: { mc.toggleAnnotationFromShortcut() },
            clearCanvas:      { mc.clearCanvasFromShortcut() }
        )
        shortcutManager = shortcuts
    }

    func applicationWillTerminate(_ notification: Notification) {}

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
