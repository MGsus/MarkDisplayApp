// PreferencesWindowController.swift
// MarkDisplayApp
//
// Preferences panel — programmatic NSWindow, no XIB.
// Sections: Colors (5 NSColorWell), Stroke Width (slider), Auto-Erase, Shortcuts reference.

import AppKit

class PreferencesWindowController: NSWindowController {

    // MARK: - Init

    init() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "Preferences"
        win.isReleasedWhenClosed = false
        super.init(window: win)
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI construction

    private func buildUI() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true

        let prefs = AppPreferences.shared
        var y: CGFloat = 300

        func label(_ text: String, x: CGFloat) {
            let f = NSTextField(labelWithString: text)
            f.frame = NSRect(x: x, y: y, width: 160, height: 20)
            contentView.addSubview(f)
        }

        // --- Colors ---
        label("Favourite Colors", x: 20)
        y -= 34
        for i in 0..<5 {
            let well = NSColorWell(frame: NSRect(x: CGFloat(20 + i * 54), y: y, width: 44, height: 28))
            well.color = NSColor(hex: prefs.favoriteColors[i]) ?? .red
            well.tag = i
            well.target = self
            well.action = #selector(colorWellChanged(_:))
            contentView.addSubview(well)
        }

        // --- Stroke Width ---
        y -= 50
        label("Stroke Width", x: 20)
        let slider = NSSlider(value: Double(prefs.strokeWidth), minValue: 1, maxValue: 20,
                              target: self, action: #selector(strokeWidthChanged(_:)))
        slider.frame = NSRect(x: 160, y: y, width: 180, height: 24)
        contentView.addSubview(slider)

        // --- Auto-Erase ---
        y -= 44
        label("Auto-Erase", x: 20)
        let toggle = NSButton(checkboxWithTitle: "Enabled", target: self, action: #selector(autoEraseToggled(_:)))
        toggle.frame = NSRect(x: 160, y: y, width: 90, height: 22)
        toggle.state = prefs.autoEraseEnabled ? .on : .off
        contentView.addSubview(toggle)

        let delayField = NSTextField(frame: NSRect(x: 260, y: y, width: 60, height: 22))
        delayField.stringValue = "\(Int(prefs.autoEraseDelay))s"
        delayField.target = self
        delayField.action = #selector(autoEraseDelayChanged(_:))
        delayField.placeholderString = "5s"
        contentView.addSubview(delayField)

        // --- Shortcuts reference ---
        y -= 50
        label("Shortcuts", x: 20)
        let shortcuts = NSTextField(labelWithString:
            "⌘⇧A  Toggle annotation\n⌘⇧X  Clear canvas\nP/H/E/S  Tool: pen/highlight/erase/shape\nTab  Cycle tools\n1–5  Colour slot\n⌘Z / ⌘⇧Z  Undo / Redo\nEsc  Stop annotating")
        shortcuts.frame = NSRect(x: 160, y: y - 72, width: 200, height: 100)
        shortcuts.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        shortcuts.lineBreakMode = .byWordWrapping
        shortcuts.maximumNumberOfLines = 8
        contentView.addSubview(shortcuts)
    }

    // MARK: - Actions

    @objc private func colorWellChanged(_ sender: NSColorWell) {
        var colors = AppPreferences.shared.favoriteColors
        colors[sender.tag] = sender.color.hexString
        AppPreferences.shared.favoriteColors = colors
    }

    @objc private func strokeWidthChanged(_ sender: NSSlider) {
        AppPreferences.shared.strokeWidth = CGFloat(sender.doubleValue)
    }

    @objc private func autoEraseToggled(_ sender: NSButton) {
        AppPreferences.shared.autoEraseEnabled = sender.state == .on
    }

    @objc private func autoEraseDelayChanged(_ sender: NSTextField) {
        let text = sender.stringValue.replacingOccurrences(of: "s", with: "")
        if let v = TimeInterval(text), v > 0 {
            AppPreferences.shared.autoEraseDelay = v
        }
    }
}
