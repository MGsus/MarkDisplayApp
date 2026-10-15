// PreferencesWindowController.swift
// MarkDisplayApp
//
// Preferences panel — programmatic NSWindow, no XIB.
// Sections: Colors (5 NSColorWell), Stroke Width (slider), Auto-Erase, Shortcuts reference.

import AppKit

// MARK: - Shortcut key model

/// One token in a shortcut badge row.
enum ShortcutKey {
    case ctrl           // ⌃  (SF: control)
    case cmd            // ⌘  (SF: command)
    case shift          // ⇧  (SF: shift)
    case char(String)   // literal key label, e.g. "A", "Tab", "Esc", "[", "]"
    case separator      // "/" divider between alternatives
}

// MARK: - ShortcutKeysView

/// Renders a row of key-cap badges + modifier SF Symbol glyphs inline.
final class ShortcutKeysView: NSView {

    private let keys: [ShortcutKey]

    init(keys: [ShortcutKey]) {
        self.keys = keys
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let capFont   = NSFont.systemFont(ofSize: 11, weight: .medium)
        let symConfig = NSImage.SymbolConfiguration(pointSize: 11, weight: .regular)
        let fg        = NSColor.labelColor

        var x: CGFloat = 0
        let h: CGFloat = bounds.height

        for key in keys {
            switch key {

            case .ctrl:
                x += drawSymbol("control", config: symConfig, color: fg, x: x, h: h)
            case .cmd:
                x += drawSymbol("command", config: symConfig, color: fg, x: x, h: h)
            case .shift:
                x += drawSymbol("shift", config: symConfig, color: fg, x: x, h: h)

            case .char(let label):
                x += drawKeyCap(label, font: capFont, color: fg, x: x, h: h)

            case .separator:
                let attr: [NSAttributedString.Key: Any] = [
                    .font: capFont, .foregroundColor: NSColor.tertiaryLabelColor
                ]
                let s = NSAttributedString(string: "/", attributes: attr)
                let sz = s.size()
                s.draw(at: NSPoint(x: x + 2, y: (h - sz.height) / 2))
                x += sz.width + 4
            }
        }
    }

    // MARK: - Helpers

    /// Draws an SF Symbol glyph, returns width consumed.
    private func drawSymbol(_ name: String,
                            config: NSImage.SymbolConfiguration,
                            color: NSColor,
                            x: CGFloat, h: CGFloat) -> CGFloat {
        guard let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
                            .withSymbolConfiguration(config) else { return 0 }
        let sz = img.size
        let y  = (h - sz.height) / 2
        img.draw(in: NSRect(x: x, y: y, width: sz.width, height: sz.height),
                 from: .zero, operation: .sourceOver, fraction: 1,
                 respectFlipped: true, hints: nil)
        return sz.width + 2
    }

    /// Draws a rounded-rect key-cap badge with the label centred inside, returns width consumed.
    private func drawKeyCap(_ label: String, font: NSFont, color: NSColor,
                            x: CGFloat, h: CGFloat) -> CGFloat {
        let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let s  = NSAttributedString(string: label, attributes: attr)
        let sz = s.size()
        let hPad: CGFloat = 5
        let capW  = sz.width + hPad * 2
        let capH  = h - 2
        let capY  = (h - capH) / 2

        let cap = NSRect(x: x, y: capY, width: capW, height: capH)
        let path = NSBezierPath(roundedRect: cap, xRadius: 3, yRadius: 3)

        NSColor.quaternaryLabelColor.withAlphaComponent(0.25).setFill()
        path.fill()
        NSColor.separatorColor.setStroke()
        path.lineWidth = 0.5
        path.stroke()

        s.draw(at: NSPoint(x: x + hPad, y: (h - sz.height) / 2))
        return capW + 3
    }
}

// MARK: - PreferencesWindowController

class PreferencesWindowController: NSWindowController, NSTextFieldDelegate {

    // MARK: - Init

    init() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 420),
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
        var y: CGFloat = 380

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
        let slider = NSSlider(value: Double(prefs.strokeWidth), minValue: 1, maxValue: 9,
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
        delayField.delegate = self
        delayField.placeholderString = "5s"
        contentView.addSubview(delayField)

        // --- Shortcuts reference ---
        y -= 44
        label("Shortcuts", x: 20)

        let shortcutRows: [(keys: [ShortcutKey], description: String)] = [
            ([.ctrl, .char("A")],                  "Toggle annotation"),
            ([.ctrl, .char("X")],                  "Clear canvas"),
            ([.char("F")],                         "Pen"),
            ([.char("H")],                         "Highlighter"),
            ([.char("E")],                         "Eraser"),
            ([.char("R")],                         "Rectangle shape"),
            ([.char("C")],                         "Circle shape"),
            ([.char("A")],                         "Arrow shape"),
            ([.char("Tab")],                       "Cycle tools"),
            ([.char("["), .separator, .char("]")], "Stroke width"),
            ([.char("1"), .separator, .char("5")], "Colour slot"),
            ([.cmd, .char("Z")],                   "Undo"),
            ([.cmd, .shift, .char("Z")],            "Redo"),
            ([.char("Esc")],                       "Stop annotating"),
        ]

        let rowH: CGFloat = 22
        let gridTop = y - 4
        for (i, row) in shortcutRows.enumerated() {
            let rowY = gridTop - CGFloat(i) * rowH
            let keysView = ShortcutKeysView(keys: row.keys)
            keysView.frame = NSRect(x: 160, y: rowY, width: 120, height: rowH - 2)
            contentView.addSubview(keysView)

            let desc = NSTextField(labelWithString: row.description)
            desc.frame = NSRect(x: 290, y: rowY + 1, width: 120, height: rowH - 2)
            desc.font = .systemFont(ofSize: 11)
            desc.textColor = .secondaryLabelColor
            contentView.addSubview(desc)
        }
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

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else { return }
        autoEraseDelayChanged(field)
    }
}
