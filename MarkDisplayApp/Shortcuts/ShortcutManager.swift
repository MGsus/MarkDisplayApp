// ShortcutManager.swift
// MarkDisplayApp
//
// Registers system-wide hotkeys via Carbon RegisterEventHotKey. Unlike
// NSEvent global monitors, this needs no Input Monitoring / Accessibility
// permission and works immediately, including when this app is frontmost.
//
// Default shortcuts:
//   Ctrl+A — toggle annotation mode
//   Ctrl+X — clear canvas

import AppKit
import Carbon.HIToolbox

class ShortcutManager {

    private var actions: [UInt32: () -> Void] = [:]
    private var hotKeys: [EventHotKeyRef] = []
    private var handler: EventHandlerRef?

    init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            let me = Unmanaged<ShortcutManager>.fromOpaque(userData!).takeUnretainedValue()
            me.actions[id.id]?()
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }

    deinit {
        hotKeys.forEach { UnregisterEventHotKey($0) }
        if let handler { RemoveEventHandler(handler) }
    }

    // MARK: - Registration

    func register(keyCode: Int, modifiers: Int, action: @escaping () -> Void) {
        let id = UInt32(actions.count + 1)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers),
                                         EventHotKeyID(signature: OSType(0x4D444B59), id: id),
                                         GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else { return }
        actions[id] = action
        hotKeys.append(ref)
    }

    /// Register all default application shortcuts.
    func registerDefaults(
        toggleAnnotation: @escaping () -> Void,
        clearCanvas: @escaping () -> Void
    ) {
        register(keyCode: kVK_ANSI_A, modifiers: controlKey, action: toggleAnnotation)
        register(keyCode: kVK_ANSI_X, modifiers: controlKey, action: clearCanvas)
    }
}
