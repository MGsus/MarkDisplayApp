// AppPreferences.swift
// MarkDisplayApp
//
// UserDefaults wrapper for all user-configurable settings.
// All changes are persisted immediately via computed property setters.
//
// TODO: Add KVO / NotificationCenter posting if reactive updates are needed
//       in future sub-tasks.

import AppKit

class AppPreferences {

    static let shared = AppPreferences()
    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Key {
        static let favoriteColors = "favoriteColors"
        static let strokeWidth    = "strokeWidth"
        static let activeTool     = "activeTool"
        static let autoEraseEnabled = "autoEraseEnabled"
        static let autoEraseDelay   = "autoEraseDelay"
    }

    // MARK: - Properties

    /// Five user-defined favourite colours stored as hex strings.
    var favoriteColors: [String] {
        get {
            defaults.array(forKey: Key.favoriteColors) as? [String]
                ?? ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF"]
        }
        set { defaults.set(newValue, forKey: Key.favoriteColors) }
    }

    var strokeWidth: CGFloat {
        get { CGFloat(defaults.float(forKey: Key.strokeWidth).nonZeroOr(3.0)) }
        set { defaults.set(Float(newValue), forKey: Key.strokeWidth) }
    }

    var activeTool: ToolType {
        get {
            guard let raw = defaults.string(forKey: Key.activeTool),
                  let tool = ToolType(rawValue: raw) else { return .pen }
            return tool
        }
        set { defaults.set(newValue.rawValue, forKey: Key.activeTool) }
    }

    var autoEraseEnabled: Bool {
        get { defaults.bool(forKey: Key.autoEraseEnabled) }
        set { defaults.set(newValue, forKey: Key.autoEraseEnabled) }
    }

    /// Auto-erase delay in seconds (0 = disabled).
    var autoEraseDelay: TimeInterval {
        get {
            let v = defaults.double(forKey: Key.autoEraseDelay)
            return v > 0 ? v : 5.0
        }
        set { defaults.set(newValue, forKey: Key.autoEraseDelay) }
    }
}

// MARK: - Helpers

extension NSColor {

    /// Creates a colour from "#RRGGBB"; returns nil for malformed input.
    convenience init?(hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(
            srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
            green: CGFloat((v >> 8) & 0xFF) / 255,
            blue: CGFloat(v & 0xFF) / 255,
            alpha: 1
        )
    }

    /// "#RRGGBB" representation in sRGB.
    var hexString: String {
        let c = usingColorSpace(.sRGB) ?? self
        return String(
            format: "#%02X%02X%02X",
            Int((c.redComponent * 255).rounded()),
            Int((c.greenComponent * 255).rounded()),
            Int((c.blueComponent * 255).rounded())
        )
    }
}

private extension Float {
    func nonZeroOr(_ fallback: Float) -> Float {
        self == 0 ? fallback : self
    }
}
