// ShortcutManager.swift
// MarkDisplayApp
//
// Registers global NSEvent monitors for keyboard shortcuts that fire
// even when another application is in the foreground.
//
// Default shortcuts (all modifier combos — no Accessibility permission needed):
//   Cmd+Shift+A — toggle annotation mode
//   Cmd+Shift+X — clear canvas

import AppKit

class ShortcutManager {

    private var monitors: [Any] = []

    deinit {
        monitors.forEach { NSEvent.removeMonitor($0) }
    }

    // MARK: - Registration

    /// Register a global key-down monitor for a modifier + character key.
    /// A global monitor covers other apps; a local monitor covers our own overlay
    /// (global monitors never see events delivered to this app).
    func register(modifiers: NSEvent.ModifierFlags, character: String, action: @escaping () -> Void) {
        func matches(_ event: NSEvent) -> Bool {
            event.modifierFlags.intersection(.deviceIndependentFlagsMask) == modifiers
                && event.charactersIgnoringModifiers?.lowercased() == character.lowercased()
        }
        if let global = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: { event in
            if matches(event) { action() }
        }) {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { event in
            guard matches(event) else { return event }
            action()
            return nil
        }) {
            monitors.append(local)
        }
    }

    /// Register all default application shortcuts.
    func registerDefaults(
        toggleAnnotation: @escaping () -> Void,
        clearCanvas: @escaping () -> Void
    ) {
        register(modifiers: [.control], character: "a", action: toggleAnnotation)
        register(modifiers: [.control], character: "x", action: clearCanvas)
    }
}
